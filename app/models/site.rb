# frozen_string_literal: true

class Site < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_one :sites_neighbourhood, dependent: :destroy
  has_one :primary_neighbourhood, -> { where(sites_neighbourhoods: { relation_type: 'Primary' }) }, source: :neighbourhood, through: :sites_neighbourhood

  has_many :sites_neighbourhoods, dependent: :destroy
  has_many :secondary_neighbourhoods, -> { where(sites_neighbourhoods: { relation_type: 'Secondary' }) }, source: :neighbourhood, through: :sites_neighbourhoods

  has_many :neighbourhoods, through: :sites_neighbourhoods

  has_and_belongs_to_many :supporters

  belongs_to :site_admin, class_name: 'User'

  accepts_nested_attributes_for :sites_neighbourhood
  accepts_nested_attributes_for :sites_neighbourhoods, reject_if: ->(c) { c[:neighbourhood_id].blank? }, allow_destroy: true

  validates :name, :slug, :domain, presence: true

  mount_uploader :logo, SiteLogoUploader
  mount_uploader :footer_logo, SiteLogoUploader
  mount_uploader :hero_image, HeroImageUploader

  # def primary_site_turf
  #   sites_turfs.where(relation_type: 'Primary').first
  # end
  #
  # def secondary_site_turfs
  #   sites_turfs.where(relation_type: 'Secondary')
  # end

  def to_s
    "#{id}: #{name}"
  end
end
