# frozen_string_literal: true

class Neighbourhood < ApplicationRecord
  has_many :sites_neighbourhoods, dependent: :destroy
  has_many :sites, through: :sites_neighbourhoods

  has_many :neighbourhoods_users, dependent: :destroy
  has_many :users, through: :neighbourhoods_users

  # validates :name, presence: true
  validates :WD19CD, uniqueness: true, allow_blank: true

  validates :WD19CD, :LAD19CD, :CTY19CD, :RGN19CD,
            length: { is: 9 },
            allow_blank: true

  class << self
    def create_from_postcodesio_response(res)
      n = Neighbourhood.new
      n.name = res['admin_ward']
      n.name_abbr = res['admin_ward']
      n.ward = res['admin_ward']
      n.district = res['admin_district']
      n.county = res['admin_county']
      n.region = res['region']
      n.WD19CD = res['codes']['admin_ward']
      n.WD19NM = res['admin_ward']
      n.LAD19CD = res['codes']['admin_district']
      n.LAD19NM = res['admin_district']
      n.CTY19CD = res['codes']['admin_county']
      n.CTY19NM = res['admin_county']
      # Region not currently returned by postcodes.io
      # n.RGN19CD = res['']
      # n.RGN19NM = res['']

      n.save! && n
    end
  end
end
