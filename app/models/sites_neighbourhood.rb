# frozen_string_literal: true

class SitesNeighbourhood < ApplicationRecord
  self.table_name = 'sites_neighbourhoods'
  belongs_to :neighbourhood
  belongs_to :site
  validates_uniqueness_of :neighbourhood_id, scope: :site_id, message: 'Neighbourhood cannot be assigned more than once to a site'
end
