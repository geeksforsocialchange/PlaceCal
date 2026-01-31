# frozen_string_literal: true

namespace :counters do
  desc 'Refresh all cached counter columns (sites and neighbourhoods)'
  task refresh_all: :environment do
    puts 'Refreshing site counter caches...'
    Site.refresh_all_counts!
    puts "Updated #{Site.count} sites"

    puts 'Refreshing neighbourhood partner counts...'
    Neighbourhood.refresh_partners_count!
    puts 'Done'
  end
end
