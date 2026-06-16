# frozen_string_literal: true

require_relative '../neighbourhood_importer'
require_relative '../neighbourhood_remapper'

namespace :neighbourhoods do
  desc 'find or create all available neighbourhoods'
  task import: :environment do
    NeighbourhoodImporter.run
  end

  desc 'remap site/service area/user links from old-release neighbourhoods to the latest release (DRY_RUN=1 to preview)'
  task remap_associations: :environment do
    NeighbourhoodRemapper.run(dry_run: ENV['DRY_RUN'].present?)
  end
end
