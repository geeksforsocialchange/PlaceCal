# frozen_string_literal: true

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
