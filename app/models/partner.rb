class Partner < ApplicationRecord
  has_and_belongs_to_many :events
  has_and_belongs_to_many :users
  has_and_belongs_to_many :venues

  has_many :calendars
end
