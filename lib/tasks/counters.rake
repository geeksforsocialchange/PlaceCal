# frozen_string_literal: true

namespace :counters do
  desc 'Refresh cached partner and event counts for all sites'
  task sites: :environment do
    puts 'Refreshing site counter caches...'
    Site.refresh_all_counts!
    puts "Updated #{Site.count} sites"
  end

  desc 'Refresh cached partner counts for all neighbourhoods'
  task neighbourhoods: :environment do
    puts 'Refreshing neighbourhood partner counts...'
    Neighbourhood.refresh_partners_count!
    puts 'Done'
  end

  desc 'Refresh all cached counter columns (sites and neighbourhoods)'
  task refresh_all: %i[sites neighbourhoods]
end
