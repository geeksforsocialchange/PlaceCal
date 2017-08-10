class Event < ApplicationRecord
  has_and_belongs_to_many :organizations

  belongs_to :venue
end
