# frozen_string_literal: true

class Neighbourhood < ApplicationRecord
  has_many :sites_neighbourhoods, dependent: :destroy
  has_many :sites, through: :sites_neighbourhoods

  has_many :neighbourhoods_users, dependent: :destroy
  has_many :users, through: :neighbourhoods_users

  validates :name, :ward, presence: true
  validates :WD19CD, uniqueness: true, allow_blank: true

  class << self
    def create_from_admin_ward admin_ward
      t = Neighbourhood.new
      t.name = admin_ward
      # t.slug = admin_ward.downcase.gsub(/ /, "-")
      t.save && t
    end
  end
end
