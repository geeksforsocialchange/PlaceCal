# app/models/partner.rb
class Partner < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_and_belongs_to_many :users
  has_and_belongs_to_many :places

  has_many :calendars
  has_many :events

  belongs_to :address, required: false

  validates_presence_of :name
  validates_uniqueness_of :name

  mount_uploader :image, ImageUploader

  def to_s
    name
  end
end
