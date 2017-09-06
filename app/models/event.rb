class Event < ApplicationRecord
  has_and_belongs_to_many :partners

  belongs_to :place
end
