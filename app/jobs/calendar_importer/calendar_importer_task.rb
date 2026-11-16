# frozen_string_literal: true

class CalendarImporter::CalendarImporterTask
  MAX_OCCURENCES = 20_000
  # How long a feed stays empty before its upcoming events are removed
  EMPTY_FEED_GRACE = 48.hours

  attr_reader :calendar,
              :from_date,
              :force_import

  def initialize(calendar, from_date, force_import)
    @calendar = calendar
    @from_date = from_date
    @force_import = force_import
  end

  def run
    parsed_events = event_data_from_parser
    # An edit during this import cleared the empty-feed record; this run's feed is no longer the calendar's
    feed_edited = calendar.feed_edited_since_loaded?
    calendar.flag_feed_empty!(calendar_source.events.empty?) if source_read? && !feed_edited

    if parsed_events.present?
      # this can be useful if you want to force import on your local machine
      # if @force_import
      #   calendar.events.destroy_all
      # end

      parsed_events.each do |parsed_event|
        break unless within_occurence_limit?(parsed_event)

        process_event parsed_event
      end

      # Events past the limit were never processed, so their rows would look stale
      purge_stale_events_from_calendar unless @occurence_limit_reached
    end

    handle_empty_feed if calendar.feed_empty_since && !feed_edited

    add_unreadable_address_notices

    calendar.flag_complete_import_job! notices, parser::KEY
    calendar.flag_checksum_change!(calendar_source.checksum) if calendar_source.checksum_changed
  rescue CalendarImporter::Exceptions::SourceUnavailable
    calendar.flag_skipped_import_job! [I18n.t('admin.calendars.importer.source_unavailable', source: parser::NAME)]
  end

  private

  def notices
    @notices ||= []
  end

  def active_event_uids
    @active_event_uids ||= Set.new
  end

  def parser
    @parser ||= CalendarImporter::CalendarImporter.new(calendar).parser
  end

  # Get a properly formatted event list from the source
  def calendar_source
    @calendar_source ||= parser.new(
      calendar,
      from: from_date,
      force_import:
    ).calendar_to_events
  end

  # Unchanged feeds are skipped without being parsed
  def source_read?
    force_import || calendar_source.checksum_changed
  end

  # Keep an empty feed's upcoming events for a grace period, since a broken source can also look empty
  def handle_empty_feed
    since = calendar.feed_empty_since
    upcoming = calendar.events.upcoming
    dates = { since: I18n.l(since.to_date, format: :day_month_year) }

    if since <= EMPTY_FEED_GRACE.ago && upcoming.exists?
      upcoming.destroy_all
      notices << I18n.t('admin.calendars.importer.feed_empty_removed', **dates)
    elsif upcoming.exists?
      removal = I18n.l((since + EMPTY_FEED_GRACE).to_date, format: :day_month_year)
      notices << I18n.t('admin.calendars.importer.feed_empty', count: upcoming.count, removal:, **dates)
    else
      notices << I18n.t('admin.calendars.importer.feed_empty_no_events', **dates)
    end
  end

  # @return [Hash{Symbol => Array<CalendarImporter::Events::Base>}] events whose location couldn't be read, by reason
  def unreadable_addresses
    @unreadable_addresses ||= Hash.new { |hash, reason| hash[reason] = [] }
  end

  # One notice per reason, so a feed with no postcodes doesn't give a notice for every event
  def add_unreadable_address_notices
    unreadable_addresses.each do |reason, events|
      examples = events.uniq(&:location).first(3).map do |event|
        I18n.t('admin.calendars.importer.unreadable_address.example', summary: event.summary, location: event.location)
      end
      notices << I18n.t("admin.calendars.importer.unreadable_address.#{reason}", count: events.size, examples: examples.to_sentence)
    end
  end

  # Send the event data to be imported
  def event_data_from_parser
    return [] if !force_import && !calendar_source.checksum_changed

    notices.concat(calendar_source.notices)
    calendar_source.events.map do |event_data|
      CalendarImporter::EventResolver.new(event_data, calendar, notices, from_date)
    end
  end

  # Attempt to create each event
  def process_event(parsed_event)
    return if parsed_event.private?
    return if parsed_event.no_occurences?

    parsed_event.determine_online_location

    parsed_event.determine_location_for_strategy
    unreadable_addresses[parsed_event.unreadable_address_reason] << parsed_event.data if parsed_event.unreadable_address_reason

    active_event_uids << parsed_event.uid

    parsed_event.save_all_occurences
  rescue CalendarImporter::LocationResolver::Problem => e
    # A problem with the calendar's settings, so every event hits it; say it once
    notices << e.message unless notices.include?(e.message)
  end

  def within_occurence_limit?(parsed_event)
    return true if parsed_event.private?

    @occurence_count = @occurence_count.to_i + parsed_event.occurences.size
    return true if @occurence_count <= MAX_OCCURENCES

    notices << I18n.t('admin.calendars.importer.calendar_occurrence_limit', count: MAX_OCCURENCES)
    @occurence_limit_reached = true
    false
  end

  def purge_stale_events_from_calendar
    all_event_uids = Set.new(calendar.events.upcoming.pluck(:uid))
    stale_event_uids = all_event_uids - active_event_uids

    calendar.events.upcoming.where(uid: stale_event_uids).destroy_all
  end
end
