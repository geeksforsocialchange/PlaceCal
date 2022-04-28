class CalendarImporterJob < ApplicationJob
  queue_as :default

  def perform(calendar_id, from_date)
    calendar = Calendar.find(calendar_id)

    puts "Importing events for calendar #{calendar.name} (ID #{calendar_id}) for #{calendar.place.try(:name)}"

    # calendar.import_events(from)
    CalendarImporter::CalendarImporterTask.new(calendar, from_date).run

  rescue CalendarImporter::EventResolver::Problem => e
    error = "Could not automatically import data for calendar #{calendar.name} (id #{calendar_id}):  #{e}"
    calendar.critical_import_failure e
    puts error
    Rollbar.error error
    
  rescue CalendarImporter::CalendarImporter::InaccessibleFeed, CalendarImporter::CalendarImporter::UnsupportedFeed => e
    calendar.critical_import_failure e

  rescue StandardError => e
    # TODO: Inform admin(s) when this fails
    error = "Could not automatically import data for calendar #{calendar.name} (id #{calendar_id}):  #{e}"
    calendar.critical_import_failure error
    puts error
    Rollbar.error error
  end
end
