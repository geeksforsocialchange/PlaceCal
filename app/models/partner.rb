class Partner < ApplicationRecord
  has_and_belongs_to_many :events
  has_and_belongs_to_many :users
  has_and_belongs_to_many :places

  has_many :calendars
  belongs_to :address, required: false

  validates_presence_of :name
  validates_uniqueness_of :name

  def to_s
    name
  end
end
