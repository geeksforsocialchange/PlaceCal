class CalendarImporterJob < ApplicationJob
  queue_as :default

  def calendar
    @calendar ||= Calendar.find(@calendar_id)
  end

  # Imports all events from a given calendar
  # @param calendar_id [int] The ID of the Calendar object to import from
  # @param from_date [Date] The Date from which to import from
  def perform(calendar_id, from_date, force_import)
    @calendar_id = calendar_id

    print "Importing events for calendar #{calendar.name} (ID #{calendar.id})"
    print " for place #{calendar.place.name} (ID #{calendar.place.id})" if calendar.place
    print " is forced" if force_import
    print "\n"

    # calendar.import_events(from)
    CalendarImporter::CalendarImporterTask.new(calendar, from_date, force_import).run

  rescue CalendarImporter::EventResolver::Problem => e
    report_error e, "Could not automatically import data"

  rescue CalendarImporter::CalendarImporter::UnsupportedFeed => e
    report_error e, "Calendar has unsupported feed URL"

  rescue CalendarImporter::CalendarImporter::InaccessibleFeed => e
    report_error e, "Calendar has inaccessible feed URL"

  rescue StandardError => e
    report_error e, "Could not automatically import data"
    raise e unless Rails.env.production?
  end

  private

  def report_error(e, message)
    full_message = "#{message} for calendar #{calendar.name} (id #{calendar.id}):  #{e}"
    backtrace = e.backtrace[...6]

    calendar.critical_import_failure full_message
    puts full_message, backtrace if Rails.env.dev?
    Rollbar.error error, { exception_type: e.class.name, backtrace: backtrace }
  end
end
