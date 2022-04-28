class CalendarImporterJob < ApplicationJob
  queue_as :default

  # Imports all events from a given calendar
  # @param calendar_id [int] The ID of the Calendar object to import from
  # @param from_date [Date] The Date from which to import from
  def perform(calendar_id, from_date)
    calendar = Calendar.find(calendar_id)

    puts "Importing events for calendar #{calendar.name} (ID #{calendar_id}) for #{calendar.place.try(:name)}"

    # calendar.import_events(from)
    CalendarImporter::CalendarImporterTask.new(calendar, from_date).run
  rescue CalendarImporter::EventResolver::Problem => e
    error = "Could not automatically import data for calendar #{calendar.name} (id #{calendar_id}):  #{e}"
    backtrace = e.backtrace[...6]

    calendar.critical_import_failure e
    puts error, backtrace
    Rollbar.error error, { exception_type: 'EventResolver::Problem', backtrace: backtrace }
  rescue CalendarImporter::CalendarImporter::InaccessibleFeed, CalendarImporter::CalendarImporter::UnsupportedFeed => e
    error = "Calendar has inaccessible / unsupported feed #{calendar.name} (id #{calendar_id}):  #{e}"
    backtrace = e.backtrace[...6]

    calendar.critical_import_failure e
    puts error, backtrace
    Rollbar.error error, { exception_type: 'unsupported/inaccessible', backtrace: backtrace }
  rescue StandardError => e
    # TODO: Inform admin(s) when this fails
    error = "Could not automatically import data for calendar #{calendar.name} (id #{calendar_id}):  #{e}"
    backtrace = e.backtrace[...6]

    calendar.critical_import_failure error
    puts error, backtrace
    Rollbar.error error, { exception_type: 'StandardError', backtrace: backtrace }
  end
end
