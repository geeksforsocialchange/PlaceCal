# frozen_string_literal: true

# == Schema Information
#
# Table name: service_areas
#
#  id               :bigint           not null, primary key
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  neighbourhood_id :bigint           not null
#  partner_id       :bigint           not null
#
# Indexes
#
#  index_service_areas_on_neighbourhood_id_and_partner_id  (neighbourhood_id,partner_id) UNIQUE
#  index_service_areas_on_partner_id                       (partner_id)
#
# Foreign Keys
#
#  fk_rails_...  (neighbourhood_id => neighbourhoods.id)
#  fk_rails_...  (partner_id => partners.id)
#
class ServiceArea < ApplicationRecord
  # ==== Includes / Extends ====
  include NeighbourhoodCacheInvalidator

  # ==== Associations ====
  belongs_to :neighbourhood
  belongs_to :partner

  # ==== Validations ====
  # A partner cannot have the same neighbourhood added as a service area
  # more than once. Validating neighbourhood_id (rather than partner)
  # attaches the error to the neighbourhood, giving a clearer message.
  validates :neighbourhood_id,
            uniqueness: {
              scope: :partner_id,
              message: 'cannot be added more than once as a service area'
            }

  # ==== Callbacks ====
  after_commit :invalidate_neighbourhood_partners_count!
end
