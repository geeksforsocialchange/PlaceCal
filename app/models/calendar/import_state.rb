# frozen_string_literal: true

# Import state changes. None of them move updated_at, which records edits to the calendar's settings.
module Calendar::ImportState
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
      importer_used:
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

  # Mark calendar as having an unreachable/invalid source.
  # NOTE: reloads the model, discarding unsaved changes from the import.
  # @param problem [String] description of the source issue
  # @return [void]
  def flag_bad_source!(problem)
    reload
    return unless calendar_state.in_worker?

    save_state! calendar_state: :bad_source, critical_error: problem
  end

  # Flag that an import error occurred; the hourly scan requeues it so it retries once the fault clears.
  # NOTE: reloads the model, discarding unsaved changes from the import.
  # @param problem [String] description of the import failure
  # @return [void]
  def flag_error_import_job!(problem)
    reload
    return unless calendar_state.in_worker?

    # An invalid calendar still has to leave in_worker, or the hourly scan never requeues it
    assign_attributes calendar_state: :error, critical_error: problem
    save touch: false, validate: false
  end

  private

  def save_state!(attributes)
    assign_attributes(attributes)
    save!(touch: false)
  end
end
