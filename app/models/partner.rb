# app/models/partner.rb
class Partner < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_and_belongs_to_many :users
  has_and_belongs_to_many :places

  has_many :calendars
  has_many :events

  accepts_nested_attributes_for :places, :allow_destroy => true
  accepts_nested_attributes_for :calendars, :allow_destroy => true

  belongs_to :address, required: false

  validates_presence_of :name
  validates_uniqueness_of :name

  mount_uploader :image, ImageUploader

  def to_s
    name
  end

  def permalink
    "https://placecal.org/partners/#{id}"
  end
end
