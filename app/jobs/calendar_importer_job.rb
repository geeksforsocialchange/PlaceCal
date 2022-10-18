# frozen_string_literal: true

class CalendarImporterJob < ApplicationJob
  queue_as :default

  rescue_from CalendarImporter::CalendarImporter::UnsupportedFeed do |exception|
    report_error exception, 'Calendar URL is not supported'
  end

  rescue_from CalendarImporter::CalendarImporter::InaccessibleFeed do |exception|
    report_error exception, 'Calendar URL is not accessible'
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
    # puts full_message, backtrace if Rails.env.development?
    # Rollbar.error full_message, { exception_type: e.class.name, backtrace: backtrace }
  end
end
