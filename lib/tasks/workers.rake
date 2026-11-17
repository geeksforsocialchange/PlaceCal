# frozen_string_literal: true

namespace :workers do
  desc 'Remove every queued job and reset calendars waiting to import'
  task purge_all: :environment do
    puts 'Removing every Solid Queue job...'
    SolidQueue::Job.delete_all

    puts 'Resetting calendars that were queued or importing...'
    Calendar.where(calendar_state: %i[in_worker in_queue]).update_all(calendar_state: :idle, import_job_id: nil) # rubocop:disable Rails/SkipsModelValidations
  end

  desc 'Show failed jobs and their errors (pipe into less)'
  task inspect_errors: :environment do
    SolidQueue::FailedExecution.includes(:job).find_each do |failed|
      pp class_name: failed.job.class_name, arguments: failed.job.arguments, error: failed.error
    end
  end
end
