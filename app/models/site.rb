# frozen_string_literal: true

class Site < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_one :sites_turf, dependent: :destroy
  has_one :primary_turf, -> { where(sites_turfs: { relation_type: 'Primary' }) }, source: :turf, through: :sites_turf

  has_many :sites_turfs, dependent: :destroy
  has_many :secondary_turfs, -> { where(sites_turfs: { relation_type: 'Secondary' }) }, source: :turf, through: :sites_turfs

  belongs_to :site_admin, class_name: 'User'

  accepts_nested_attributes_for :sites_turf
  accepts_nested_attributes_for :sites_turfs, reject_if: ->(c) { c[:turf_id].blank? }

  validates :name, :slug, :domain, presence: true

  mount_uploader :logo, SiteLogoUploader
  mount_uploader :hero_image, HeroImageUploader
end
