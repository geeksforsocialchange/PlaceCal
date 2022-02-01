# frozen_string_literal: true

class SitesNeighbourhood < ApplicationRecord
  self.table_name = 'sites_neighbourhoods'
  belongs_to :neighbourhood
  belongs_to :site
  validates :neighbourhood_id,
            uniqueness: {
              scope: :site_id,
              message: 'Neighbourhood cannot be assigned more than once to a site'
            }

  def name
    neighbourhood.to_s
  end
end
