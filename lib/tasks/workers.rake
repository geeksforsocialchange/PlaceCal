# frozen_string_literal: true

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
      c.import_job_id = nil
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
end
