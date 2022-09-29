class ServiceArea < ApplicationRecord
  belongs_to :neighbourhood
  belongs_to :partner

  validates :partner, uniqueness: { scope: :neighbourhood }
end
