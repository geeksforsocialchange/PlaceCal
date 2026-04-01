# frozen_string_literal: true

class SitesNeighbourhood < ApplicationRecord
  # -- Constants --
  self.table_name = 'sites_neighbourhoods'

  # -- Attributes --
  attribute :relation_type, :string

  # -- Associations --
  belongs_to :neighbourhood
  belongs_to :site

  # -- Validations --
  validates :neighbourhood_id,
            uniqueness: {
              scope: :site_id,
              message: 'Neighbourhood cannot be assigned more than once to a site'
            }

  # -- Instance methods --
  def name
    neighbourhood.to_s
  end
end
