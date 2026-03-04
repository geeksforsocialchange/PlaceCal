# frozen_string_literal: true

# Whenever schedule — generates crontab entries for production
# See: https://github.com/javan/whenever
#
# Update the crontab with: whenever --update-crontab
# Preview with:            whenever
#
# Future: migrate to Solid Queue recurring tasks (see #3013)

set :output, '/proc/1/fd/1' # Log to container stdout

every 1.hour do
  rake 'events:scan_for_calendars_needing_import'
end

every 1.day, at: '4:00 am' do
  rake 'events:deduplicate'
end

every 1.day, at: '4:30 am' do
  rake 'counters:refresh_all'
end

every 1.day, at: '5:30 am' do
  rake 'db:clean_bad_addresses'
end
