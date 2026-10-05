# frozen_string_literal: true

# == Schema Information
#
# Table name: sites_neighbourhoods
#
#  id               :bigint           not null, primary key
#  relation_type    :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  neighbourhood_id :bigint           not null
#  site_id          :bigint           not null
#
# Indexes
#
#  index_sites_neighbourhoods_neighbourhood_id_site_id  (neighbourhood_id,site_id) UNIQUE
#  index_sites_neighbourhoods_site_id                   (site_id)
#
# Foreign Keys
#
#  fk_rails_...  (neighbourhood_id => neighbourhoods.id)
#  fk_rails_...  (site_id => sites.id)
#
class SitesNeighbourhood < ApplicationRecord
  # ==== Constants ====

  self.table_name = 'sites_neighbourhoods'

  # ==== Attributes ====
  attribute :relation_type, :string

  # ==== Associations ====
  belongs_to :neighbourhood
  belongs_to :site

  # ==== Validations ====
  validates :neighbourhood_id,
            uniqueness: {
              scope: :site_id,
              message: 'Neighbourhood cannot be assigned more than once to a site'
            }

  # ==== Instance methods ====

  # @return [String] neighbourhood display name
  def name
    neighbourhood.to_s
  end
end
