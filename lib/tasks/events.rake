# frozen_string_literal: true

namespace :import do
  # No data for calendar of type `other` right now.
  task all_events: :environment do
    from = Date.current.beginning_of_day
    Calendar.find_each do |calendar|
      CalendarImporterJob.perform_later calendar.id, from
    end
  end

  task :events_from_source, [:calendar_id] => [:environment] do |_t, args|
    from = Date.current.beginning_of_day
    calendar_id = args[:calendar_id]

    CalendarImporterJob.perform_later calendar_id, from
  end

  # calendar_id - object id of calendar to be imported.
  # from - import events starting from this date. Must use format 'yyyy-mm-dd'.

  task :past_events_from_source, %i[calendar_id from] => [:environment] do |_t, args|
    from = Time.zone.parse(args[:from])
    calendar_id = args[:calendar_id]

    CalendarImporterJob.perform_later calendar_id, from
  end

  task purge_papertrail: :environment do
    PaperTrail::Version.all.delete_all
  end
end

