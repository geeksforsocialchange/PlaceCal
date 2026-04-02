# frozen_string_literal: true

class NeighbourhoodsUser < ApplicationRecord
  # ==== Associations ====
  belongs_to :neighbourhood
  belongs_to :user

  # ==== Validations ====
  validates :neighbourhood_id,
            uniqueness: {
              scope: :user_id,
              message: 'User cannot be assigned more than once to a neighbourhood'
            }
end
