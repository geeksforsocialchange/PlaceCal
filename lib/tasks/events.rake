# frozen_string_literal: true

namespace :import do
  desc 'scan for calendars to send to the importer worker'
  task :scan_for_calendars_needing_import, %i[force_import from] => [:environment] do |_t, args|

    force_import = to_boolean(args[:force_import])
    from = to_date(args[:from])

    scope = Calendar

    # this could be useful?
    # scope = scope.where_idle if force_import == false

    scope.find_each do |calendar|
      puts "queueing #{calendar.name}"
      calendar.queue_for_import! force_import, from
    end
  end

  # rake import:all_events
  #
  # description:
  #   runs the importer across all calendars in the calling process (does not queue for worker)
  #
  # args:
  #   force_import: [boolean, default=false] act like this calendar has no existing events and force their overwrite
  #   from: [date, dd-mm-yyyy, default=today] use this date as the start point
  #   silence_db_exceptions: [boolean, default=false] activerecord exceptions should be ignored (will only
  #     work in development mode).
  #
  # so e.g. `rails import_all_events[true,01-01-2000,true]
  #   will import all events from 1st january 2000 and database problems will be logged to
  #     stdout but the task will keep running
  #
  desc 'import events from the CLI process'
  task :all_events, %i[force_import from silence_db_exceptions] => [:environment] do |_t, args|
    force_import = to_boolean(args[:force_import])
    from = to_date(args[:from])
    silence_db_exceptions = to_boolean(args[:silence_db_exceptions])

    puts "Importing all events. force_import=#{force_import}, from=#{from}, silence_db_exceptions=#{silence_db_exceptions}"
    puts "Running in '#{Rails.env}' environment"

    Calendar.find_each do |calendar|
      calendar.update calendar_state: :in_queue
      CalendarImporterJob.perform_now calendar.id, from, force_import, silence_db_exceptions

    #rescue StandardError => e
    #  puts "\n"
    #  puts "#{e.class}: bad thing: #{e}"
    #  puts e.backtrace
    #  puts '-' * 20
    end
  end

  # Import one or many events from source
  # @param args A list of calendar IDs
  #   e.g. rails import:events_from_source[1234,12,34,56]
  task :events_from_source, [] => [:environment] do |_t, args|
    args.extras.each do |calendar_id|
      from = Date.current.beginning_of_day
      # Generally if you're importing by hand you want to avoid the checksum
      force_import = true

      CalendarImporterJob.perform_now calendar_id, from, force_import
    end
  end

  # calendar_id - object id of calendar to be imported.
  # from - import events starting from this date. Must use format 'yyyy-mm-dd'.
  #   e.g. rails import:past_events_from_source[123,'1950-01-01',true]
  task :past_events_from_source, %i[calendar_id from force_import] => [:environment] do |_t, args|
    from = to_date(args[:from])
    calendar_id = args[:calendar_id]
    force_import = to_boolean(args[:force_import])

    CalendarImporterJob.perform_now calendar_id, from, force_import
  end

  desc 'empty the papertrail table for calendars'
  task purge_papertrail: :environment do
    PaperTrail::Version.all.delete_all
  end

  private

  def to_boolean(value)
    (@boolean ||= ActiveModel::Type::Boolean.new).cast value
  end

  def to_date(value)
    return Date.current.beginning_of_day if value.blank?
    Date.parse value
  end
end
