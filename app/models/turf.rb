# frozen_string_literal: true

class Turf < ApplicationRecord
  extend Enumerize
  self.table_name = 'turfs'

  enumerize :turf_type, in: %i[interest neighbourhood]

  has_and_belongs_to_many :users
  has_and_belongs_to_many :partners
  has_and_belongs_to_many :places

  validates :name, :slug, presence: true
  validates :name, :slug, uniqueness: true

  after_save :update_users

  class << self
    def create_from_admin_ward admin_ward
      t = Turf.new
      t.name = admin_ward
      t.slug = admin_ward.downcase.gsub(/ /, "-")
      t.turf_type = 'neighbourhood'
      t.save && t
    end
  end

  private

  def update_users
    users.each(&:update_role)
  end
end


# Neighbourhood turfs:
#
# Any entity that can belong to turfs must belong to no more than one neighbourhood turf.
# Neighbourhood turfs are equivalent to electoral wards irl.
# Postecodes.io returns an admin_ward for successfully geocoded postcodes.
# Postcodes.io geocoding can therefore be used to assign an entity to exactly one neighbourhood turf.
