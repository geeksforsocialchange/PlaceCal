# frozen_string_literal: true

require 'yaml'

namespace :workers do
  desc 'Clear and remove all jobs'
  task purge_all: :environment do
    puts 'Force stopping all workers...'

    # Force stop of all workers
    Rake::Task['jobs:clear'].invoke

    puts 'Purging the workers table to remove zombie jobs'

    # Purge the workers table to remove zombie jobs
    ActiveRecord::Base.connection.execute('truncate delayed_jobs')

    puts 'Reset Calendars that have :in_worker or :in_queue'

    # Reset the :in_worker and :in_queue
    Calendar.where(calendar_state: %i[in_worker in_queue]).each do |c|
      c.calendar_state = :idle
      c.save!
    end
  end

  desc 'Show any salient worker errors (You should pipe this into less)'
  task inspect_errors: :environment do
    workers = ActiveRecord::Base.connection
                                .execute('select * from delayed_jobs')
                                .to_a
                                .reject { |w| w[:last_error].nil? }

    workers.each { |w| pp w }
  end

  # This is patchy and we should move to a callback-based system. Works for now though
  desc 'Synchronise Calendars with job state'
  task sync_state: :environment do
    puts 'Finding active workers...'

    # Find all the Calendars that are actually running
    active_calendars = ActiveRecord::Base.connection.execute('select * from delayed_jobs').to_a.map do |w|
      # We need to strip the first line because Rails adds some non-YAML
      handler_content = w['handler'].lines[1..].join
      job_data = YAML.safe_load(handler_content)

      # Calendar ID is the first argument to the job
      job_data['job_data']['arguments'].first
    end

    puts 'Finding Calendars listed as active...'

    # Find all the Calendars that are listed as running
    listed_active_calendars = Calendar.where(calendar_state: %i[in_worker in_queue]).map(&:id)

    pp [active: active_calendars, listed_active_calendars: listed_active_calendars]

    # Prune the listed Calendars to find ones that are not running, but are listed as such
    ids_to_unset = listed_active_calendars.reject { |calendar_id| active_calendars.include?(calendar_id) }

    puts "Calendar IDs listed as running that are not running: #{ids_to_unset}"
    puts 'Removing those calendars...' if ids_to_unset.length.positive?

    # Set the Calendars that are not running as such
    ids_to_unset.each do |id|
      c = Calendar.find(id)
      c.calendar_state = :idle
      c.save!
    end

    puts 'Done.'
  end
end
