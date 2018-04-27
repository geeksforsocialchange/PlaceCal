class Turf < ApplicationRecord
  extend FriendlyId
  extend Enumerize
  self.table_name = 'turfs'
  friendly_id :name, use: :slugged

  enumerize :turf_type, in: %i[interest neighbourhood]

  has_and_belongs_to_many :users
  has_and_belongs_to_many :partners
  has_and_belongs_to_many :places

  validates :name, :slug, presence: true

end
