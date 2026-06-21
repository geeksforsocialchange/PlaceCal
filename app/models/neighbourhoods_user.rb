# frozen_string_literal: true

# == Schema Information
#
# Table name: neighbourhoods_users
#
#  id               :bigint           not null, primary key
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  neighbourhood_id :bigint           not null
#  user_id          :bigint           not null
#
# Indexes
#
#  index_neighbourhoods_users_neighbourhood_id_user_id  (neighbourhood_id,user_id) UNIQUE
#  index_neighbourhoods_users_on_user_id                (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (neighbourhood_id => neighbourhoods.id)
#  fk_rails_...  (user_id => users.id)
#
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
