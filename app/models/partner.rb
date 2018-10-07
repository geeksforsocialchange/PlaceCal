# frozen_string_literal: true

# app/models/partner.rb
class Partner < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_and_belongs_to_many :users
  has_and_belongs_to_many :places
  has_and_belongs_to_many :turfs, validate: true
  has_many :calendars, dependent: :destroy
  has_many :events
  belongs_to :address, required: false

  accepts_nested_attributes_for :places, allow_destroy: true
  accepts_nested_attributes_for :calendars, allow_destroy: true

  accepts_nested_attributes_for :address, reject_if: ->(c) { c[:postcode].blank? && c[:street_address].blank? }

  validates_presence_of :name
  validates_uniqueness_of :name
  # validates_presence_of :turf_ids

  validate :require_place_if_same_as_place

  mount_uploader :image, ImageUploader

  after_save :update_users

  scope :for_site, ->(site) { joins(:address).where( addresses: { neighbourhood: site.neighbourhoods } ) }

  def to_s
    name
  end

  # def custom_validation_method_with_message
  #   errors.add(:_, "Select at least one Turf") if turf_ids.blank?
  # end

  def permalink
    "https://placecal.org/partners/#{id}"
  end

  private

  def update_users
    users.each(&:update_role)
  end

  def require_place_if_same_as_place
    if is_a_place && places.blank?
      errors.add(:base, 'Please add at least one place if one exists with same name')
    end
  end
end
