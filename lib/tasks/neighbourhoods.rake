# frozen_string_literal: true

require_relative '../neighbourhood_importer'

namespace :neighbourhoods do
  desc 'find or create all available neighbourhoods'
  task import: :environment do
    NeighbourhoodImporter.run
  end
end
