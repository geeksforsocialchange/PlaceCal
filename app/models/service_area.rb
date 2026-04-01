# frozen_string_literal: true

class ServiceArea < ApplicationRecord
  # ==== Includes / Extends ====
  include NeighbourhoodCacheInvalidator

  # ==== Associations ====
  belongs_to :neighbourhood
  belongs_to :partner

  # ==== Validations ====
  validates :partner, uniqueness: { scope: :neighbourhood }

  # ==== Callbacks ====
  after_commit :invalidate_neighbourhood_partners_count!
end
