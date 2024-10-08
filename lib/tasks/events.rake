# frozen_string_literal: true

namespace :events do
  # rails events:import_all_calendars
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
  task :import_all_calendars, %i[force_import from silence_db_exceptions] => [:environment] do |_t, args|
    force_import = to_boolean(args[:force_import])
    from = to_date(args[:from])
    silence_db_exceptions = to_boolean(args[:silence_db_exceptions])

    puts "Importing all events. force_import=#{force_import}, from=#{from}, silence_db_exceptions=#{silence_db_exceptions}"
    puts "Running in '#{Rails.env}' environment"

    Calendar.find_each do |calendar|
      calendar.update calendar_state: :in_queue
      CalendarImporterJob.perform_now calendar.id, from, force_import, silence_db_exceptions

    rescue StandardError => e
      puts "\n"
      puts "#{e.class}: bad thing: #{e}"
      puts e.backtrace
      puts '-' * 20
    end
  end

  # rails events:import_calendar
  #
  # description:
  #   Import all events from one calendar
  #
  # args:
  #   calendar_id: object id of calendar to be imported.
  #   from: start date to begin import from. Must use format 'yyyy-mm-dd'.
  #   force_import: should it force it now?
  #
  # e.g. rails events:import_calendar[123,'1950-01-01',true]
  # n.b. in zsh you may have to do rails events:import_calendar\[123\]
  #
  desc 'import a specific calendar from a given date'
  task :import_calendar, %i[calendar_id from force_import] => [:environment] do |_t, args|
    from = args[:from] ? to_date(args[:from]) : Date.current.beginning_of_day
    calendar_id = args[:calendar_id]
    force_import = args[:force_import] ? to_boolean(args[:force_import]) : true

    CalendarImporterJob.perform_now calendar_id, from, force_import
  rescue StandardError => e
    backtrace = e.backtrace[...6]
    puts "\n"
    puts "#{e.class}: bad thing: #{e}"
    puts backtrace
    puts '-' * 20
  end

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

  desc 'empty the papertrail table for calendars'
  task purge_papertrail: :environment do
    PaperTrail::Version.all.delete_all
  end

  desc 'clean up OnlineAddresses'
  task refresh_online_addresses: :environment do
    Event.where.not(online_address_id: nil).map do |e|
      e.online_address_id = nil
      e.save!
    end
    OnlineAddress.delete_all

    # TODO: For all ICS calendars, check their events and refresh their online event data
    # Currently it is impossible to do this because we don't know what parser an Event used after the fact :(
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
