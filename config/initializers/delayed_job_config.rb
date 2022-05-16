# frozen_string_literal: true

# This means that we can't tangibly run over 1hr 30m for a single calendar import.
# This tangibly means that we don't lock up the delayed job resources forever (>4 hrs lol)
Delayed::Worker.sleep_delay = 60
Delayed::Worker.max_attempts = 4
Delayed::Worker.max_run_time = 20.minutes

# These are not defaults from delayed job I just grabbed them from a website somewhere
# Delayed::Worker.destroy_failed_jobs = false
# Delayed::Worker.read_ahead = 10
# Delayed::Worker.default_queue_name = 'default'
# Delayed::Worker.delay_jobs = !Rails.env.test?
# Delayed::Worker.raise_signal_exceptions = :term
# Delayed::Worker.logger = Logger.new(File.join(Rails.root, 'log', 'delayed_job.log'))
