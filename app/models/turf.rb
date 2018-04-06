class Turf < ApplicationRecord
  self.table_name = 'turfs'
  extend Enumerize
  after_create :create_tenant

  enumerize :turf_type, in: %i[interest neighbourhood]

  has_and_belongs_to_many :users
  has_and_belongs_to_many :partners
  has_and_belongs_to_many :places

  validates :name, :slug, presence: true

end
