# frozen_string_literal: true

class CalendarImporterJob < ApplicationJob
  include CalendarImporter::Exceptions

  queue_as :default

  # Backstop for exceptions not matched by a more specific handler below. A
  # worker that dies mid-import strands the calendar in `in_worker`; an
  # *uncaught* exception does the same (the state transition never completes).
  # Flag the calendar into the terminal `error` state so it isn't stranded,
  # then re-raise so the exception still surfaces in error tracking — unexpected
  # exceptions are bugs we want to see, not silently swallow (see the
  # "does not swallow unrelated StandardError" spec).
  #
  # Declared first so the specific handlers below take precedence: rescue_from
  # matches handlers in reverse declaration order, so this only catches what
  # the others don't (and must not clobber e.g. the timeout -> bad_source map).
  rescue_from StandardError do |exception|
    report_error exception, 'Unexpected error during import'
    raise exception
  end

  rescue_from UnsupportedFeed do |exception|
    report_error exception, 'Calendar URL is not supported'
  end

  rescue_from InaccessibleFeed do |exception|
    report_bad_source_error exception.message
  end

  # Network timeouts and TLS failures are expected when scraping third-party
  # feeds that are slow or temporarily down. Treat them as an unreachable
  # source instead of letting them surface as unhandled exceptions (see issue
  # #3100). Most HTTP fetches funnel through Parsers::Base.read_http_source,
  # which already maps these to InaccessibleFeed; this backstop covers parsers
  # that make HTTP requests by other means (e.g. API and POST-based parsers).
  # RestClient::Exceptions::Timeout (the parent of RestClient's Read/OpenTimeout)
  # covers the Eventbrite parser, which fetches via RestClient/EventbriteSDK —
  # its timeout errors are not subclasses of Net::ReadTimeout/Net::OpenTimeout.
  rescue_from Net::ReadTimeout, Net::OpenTimeout, OpenSSL::SSL::SSLError,
              RestClient::Exceptions::Timeout do |exception|
    Rails.logger.warn(
      "Calendar source unreachable for calendar #{@calendar_id}: " \
      "#{exception.class} (#{exception.message})"
    )
    report_bad_source_error I18n.t('admin.calendars.wizard.source.unreachable')
  end

  rescue_from InvalidResponse do |exception|
    report_error exception, 'Calendar URL returned un-parsable data'
  end

  rescue_from ActiveRecord::ActiveRecordError do |exception|
    raise exception if !Rails.env.production? && @silence_db_exceptions == false

    report_error exception, 'Internal database error'
  end

  def calendar
    @calendar ||= Calendar.find(@calendar_id)
  end

  # Imports all events from a given calendar
  # @param calendar_id [int] The ID of the Calendar object to import from
  # @param from_date [Date] The Date from which to import from
  def perform(calendar_id, from_date, force_import, silence_db_exceptions = false)
    Calendar.record_timestamps = false

    @silence_db_exceptions = silence_db_exceptions
    @calendar_id = calendar_id

    calendar.flag_start_import_job!

    print "Importing events for calendar #{calendar.name} (ID #{calendar.id})"
    print " for place #{calendar.place.name} (ID #{calendar.place.id})" if calendar.place
    print ' is forced' if force_import
    print "\n"

    # calendar.import_events(from)
    CalendarImporter::CalendarImporterTask
      .new(calendar, from_date, force_import)
      .run
  end

  private

  def report_error(e, message)
    full_message = "#{message} for calendar #{calendar.name} (id #{calendar.id}):  #{e}"
    backtrace = e.backtrace[...6]

    # FIXME: we should not be reloading the calendar here.
    #   see note in Calendar#flag_error_import_job! for details
    calendar.reload
    calendar.flag_error_import_job! full_message
  end

  def report_bad_source_error(e)
    # problems with HTTP URLs that don't respond with status==200
    calendar.flag_bad_source! e
  end
end
