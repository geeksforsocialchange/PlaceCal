class Place < ApplicationRecord
  has_and_belongs_to_many :partners
  has_many :events
  has_many :calendars

  belongs_to :address

  def to_s
    name
  end
end
