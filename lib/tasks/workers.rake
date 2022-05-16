# frozen_string_literal: true

namespace :workers do
  desc 'Clear and remove all jobs'
  task purge_all: [] do
    # Force stop of all workers
    Rake::Task['jobs:clear'].invoke

    # Purge the workers table to remove zombie jobs
    ActiveRecord::Base.connection.execute('truncate delayed_jobs')

    # Reset the :in_worker and :in_queue
    Calendar.where(calendar_state: %i[in_worker in_queue]).each do |c|
      c.calendar_state = :idle
      c.save!
    end
  end
end
