class Place < ApplicationRecord
  has_and_belongs_to_many :partners
  has_many :events

  has_many :addresses, as: :addressable
end
