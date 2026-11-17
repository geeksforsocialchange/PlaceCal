# frozen_string_literal: true

# Finds, updates, creates and removes the rows for one source event's occurrences.
class CalendarImporter::OccurrenceSync
  Result = Data.define(:created, :updated, :unchanged, :removed, :failures)
  Failure = Data.define(:event, :errors)

  # @param attributes_for [#call] returns the attributes to save for an occurrence, without its times
  def initialize(calendar:, uid:, from_date:, occurrences:, series:, attributes_for:) # rubocop:disable Metrics/ParameterLists
    @calendar = calendar
    @from_date = from_date
    @occurrences = occurrences
    @series = series
    @attributes_for = attributes_for
    @calendar_events = calendar.events.where(uid:)
    @result = Result.new(created: [], updated: [], unchanged: [], removed: [], failures: [])
  end

  # @return [Result] the rows created, updated, unchanged and removed, and each failed save
  def call
    remove_stale_occurrences

    @occurrences.each do |occurrence|
      event_time = { dtstart: occurrence.start_time, dtend: occurrence.end_time }
      event = @series ? @calendar_events.find_by(event_time) : one_off_event

      remove_duplicates(event, event_time) if event&.persisted?

      # Not built through calendar.events, where an invalid event would fail the calendar's own save
      event ||= Event.new(calendar_id: @calendar.id)

      attributes = @attributes_for.call(occurrence).merge(event_time)
      begin
        save(event, attributes)
      rescue ActiveRecord::RecordNotUnique
        # Duplicate detected by DB constraint: find and update existing instead
        save(@calendar_events.find_by!(event_time), attributes)
      end
    end

    @result
  end

  private

  def save(event, attributes)
    if !event.update(attributes)
      @result.failures << Failure.new(event:, errors: event.errors)
    elsif event.previously_new_record?
      @result.created << event
    elsif event.saved_changes.empty?
      @result.unchanged << event
    else
      @result.updated << event
    end
  end

  # delete_all skips callbacks, so these rows get no PaperTrail version
  def remove_duplicates(event, event_time)
    duplicates = @calendar_events.where(event_time).where.not(id: event.id).to_a
    return if duplicates.empty?

    Event.where(id: duplicates.map(&:id)).delete_all
    @result.removed.concat(duplicates)
  end

  # Past rows are history, and occurrences are only generated from the import's from_date
  def remove_stale_occurrences
    upcoming = @calendar_events.where(dtstart: @from_date..)
    stale = if @series
              upcoming.without_matching_times(@occurrences.map { |o| [o.start_time, o.end_time] })
            else
              upcoming.where.not(id: one_off_event)
            end
    @result.removed.concat(stale.destroy_all)
  end

  # Reuses an existing row so a rescheduled one-off keeps its id
  def one_off_event
    occurrence = @occurrences.first
    @one_off_event ||= @calendar_events.find_by(dtstart: occurrence.start_time, dtend: occurrence.end_time) ||
                       @calendar_events.where(dtstart: @from_date..).order(:dtstart).first ||
                       @calendar_events.order(:dtstart).first
  end
end
