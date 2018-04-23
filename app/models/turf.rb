class Turf < ApplicationRecord
  self.table_name = 'turfs'
  extend Enumerize

  enumerize :turf_type, in: %i[interest neighbourhood]

  has_and_belongs_to_many :users
  has_and_belongs_to_many :partners
  has_and_belongs_to_many :places
  has_many :sites_turfs
  has_many :sites, through: :sites_turfs

  validates :name, :slug, presence: true

end
