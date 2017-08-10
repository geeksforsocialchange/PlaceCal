class Place < ApplicationRecord
  has_and_belongs_to_many :organizations
  has_many :events
end
