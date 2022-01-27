class ServiceArea < ApplicationRecord
  belongs_to :neighbourhood
  belongs_to :partner

  validates_uniqueness_of :partner, scope: :neighbourhood
end
