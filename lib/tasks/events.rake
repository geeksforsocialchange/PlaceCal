# frozen_string_literal: true

namespace :import do
  # No data for calendar of type `other` right now.
  task all_events: :environment do
    from = Date.current.beginning_of_day
    Calendar.find_each do |calendar|
      CalendarImporterJob.perform_now calendar.id, from

    rescue StandardError => e
      puts "\n"
      puts "#{e.class}: bad thing: #{e}"
      puts e.backtrace
      puts '-' * 20
    end
  end

  # Import one or many events from source
  # @param args A list of calendar IDs
  task :events_from_source, [] => [:environment] do |_t, args|
    args.extras.each do |calendar_id|
      from = Date.current.beginning_of_day

      CalendarImporterJob.perform_now calendar_id, from
    end
  end

  # calendar_id - object id of calendar to be imported.
  # from - import events starting from this date. Must use format 'yyyy-mm-dd'.

  task :past_events_from_source, %i[calendar_id from] => [:environment] do |_t, args|
    from = Time.zone.parse(args[:from])
    calendar_id = args[:calendar_id]

    CalendarImporterJob.perform_now calendar_id, from
  end

  task purge_papertrail: :environment do
    PaperTrail::Version.all.delete_all
  end
end
