# frozen_string_literal: true

# Import state changes. None of them move updated_at, which records edits to the calendar's settings.
module Calendar::ImportState
  # Staging holds a copy of real partner addresses, so only production may send.
  # @return [Boolean]
  def self.failure_emails_enabled?
    Rails.env.production? && ENV['CALENDAR_FAILURE_EMAILS_ENABLED'] == 'true'
  end

  # Push calendar into the import queue.
  # @param force_import [Boolean] bypass redundant-import checks
  # @param from_date [Time] start point for the import window
  # @return [Boolean] whether it was queued (false while an import is already queued or running)
  def queue_for_import!(force_import, from_date = Time.current)
    transaction do
      lock! # re-read the state so a scan that queued it meanwhile isn't doubled
      return false if busy?

      save_state! calendar_state: :in_queue, notices: nil, import_started_at: DateTime.current, import_job_id: nil
      job = CalendarImporterJob.perform_later id, from_date, force_import
      update_column :import_job_id, job.provider_job_id if job.try(:provider_job_id) # rubocop:disable Rails/SkipsModelValidations
      true
    end
  end

  # Flag that importing has started.
  # @return [void]
  def flag_start_import_job!
    return unless calendar_state.in_queue?

    save_state! calendar_state: :in_worker, notices: nil, import_started_at: DateTime.current
  end

  # Flag that importing completed successfully; stores notices and timestamp.
  # @param notices [Array<String>] messages generated during import
  # @param importer_used [String] name of the importer that ran
  # @return [void]
  def flag_complete_import_job!(notices, importer_used)
    return unless calendar_state.in_worker?

    save_state!(
      calendar_state: :idle,
      notices:,
      last_import_at: DateTime.current,
      critical_error: nil,
      importer_used:,
      failure_notified_at: nil
    )
  end

  # Flag that the source kept failing and this import was skipped; keeps the last successful import's time.
  # @param notices [Array<String>] why the import was skipped
  # @return [void]
  def flag_skipped_import_job!(notices)
    return unless calendar_state.in_worker?

    save_state! calendar_state: :idle, notices:
  end

  # Record whether the latest read of the feed found any events.
  # @param empty [Boolean] whether the feed parsed to no events
  # @return [void]
  def flag_feed_empty!(empty)
    since = empty ? (feed_empty_since || Time.current) : nil
    return if since == feed_empty_since

    save_state! feed_empty_since: since
  end

  # Record that the source payload checksum has changed.
  # @param checksum [String] checksum of the retrieved source payload
  # @return [void]
  def flag_checksum_change!(checksum)
    # The feed was edited during this import, so keep its checksum cleared for the next scan
    return if feed_edited_since_loaded?

    save_state! last_checksum: checksum, checksum_updated_at: DateTime.current
  end

  # Mark calendar as having an unreachable/invalid source, emailing its users if not yet told of this failure.
  # NOTE: reloads the model, discarding unsaved changes from the import.
  # @param problem [String] description of the source issue
  # @return [void]
  def flag_bad_source!(problem)
    reload
    return unless calendar_state.in_worker?

    recipients = failure_recipients(true)
    save_state! calendar_state: :bad_source, critical_error: problem, **failure_stamp(true, recipients)
    notify_failure(recipients, 'bad_source', problem)
  end

  # Flag an import error, which the hourly scan retries; emails like flag_bad_source! only when notify: is true.
  # NOTE: reloads the model, discarding unsaved changes from the import.
  # @param problem [String] description of the import failure
  # @param notify [Boolean] whether the source caused the failure, so its users should hear about it
  # @return [void]
  def flag_error_import_job!(problem, notify: false)
    reload
    return unless calendar_state.in_worker?

    recipients = failure_recipients(notify)
    assign_attributes calendar_state: :error, critical_error: problem, **failure_stamp(notify, recipients)
    # An invalid calendar still has to leave in_worker, or the hourly scan never requeues it
    notify_failure(recipients, 'error', problem) if save(touch: false, validate: false)
  end

  private

  # The hourly retry fails again each time, so only a calendar not yet told about this failure gets emails.
  def failure_recipients(notify)
    return [] if !notify || failure_notified_at || !Calendar::ImportState.failure_emails_enabled? || !organiser

    # Users with a pending invitation have no login for the admin link
    organiser.users.where('users.invitation_created_at IS NULL OR users.invitation_accepted_at IS NOT NULL').to_a
  end

  # Stamps while sending is off too, so switching it on emails nobody about failures that already exist.
  def failure_stamp(notify, recipients)
    return {} if !notify || failure_notified_at
    return {} if recipients.empty? && Calendar::ImportState.failure_emails_enabled?

    { failure_notified_at: Time.current }
  end

  def notify_failure(recipients, state, reason)
    recipients.each { |user| CalendarImportMailer.import_failed(self, user, state:, reason:).deliver_later }
  end

  def save_state!(attributes)
    assign_attributes(attributes)
    save!(touch: false)
  end
end
