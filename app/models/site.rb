class Site < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_one :sites_turf 
  has_one :primary_turf, -> { where(sites_turfs: {relation_type: 'primary'})}, source: :turf, through: :sites_turf

  has_many :sites_turfs
  has_many :turfs, through: :sites_turfs 

  validates :name, :slug, :domain, presence: true
end
