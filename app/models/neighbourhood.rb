# frozen_string_literal: true

class Neighbourhood < ApplicationRecord
  has_ancestry
  has_many :sites_neighbourhoods, dependent: :destroy
  has_many :sites, through: :sites_neighbourhoods

  has_many :neighbourhoods_users, dependent: :destroy
  has_many :users, through: :neighbourhoods_users

  # validates :name, presence: true
  validates :unit_code_value,
            length: { is: 9 },
            allow_blank: true

  def shortname
    name_abbr.presence || name
  end

  def district
    parent if unit == 'ward'
  end

  def county
    parent&.parent if unit == 'ward'
  end

  def region
    parent&.parent&.parent if unit == 'ward'
  end

  class << self
    def create_from_postcodesio_response(res)
      ward = Neighbourhood.new
      ward.name = res['admin_ward']
      ward.name_abbr = ward.name

      ward.unit = 'ward'
      ward.unit_code_key = 'WD19CD'
      ward.unit_code_value = res['codes']['admin_ward']
      ward.unit_name = ward.name

      # Postcodes.io gives us:
      # - admin_{ward,district,county,region} (can be nil)
      # - codes->admin_{ward,district,county} (set to "W99999999" if admin_* is nil?)

      district = Neighbourhood.create_or_find_by({ name: res['admin_district'],
                                                   unit: 'district',
                                                   unit_code_key: 'LAD19CD',
                                                   unit_code_value: res['codes']['admin_district'] })
      county = Neighbourhood.create_or_find_by({ name: res['admin_county'],
                                                 unit: 'county',
                                                 unit_code_key: 'CTY19CD',
                                                 unit_code_value: res['codes']['admin_county'] })
      region = Neighbourhood.create_or_find_by({ name: res['admin_region'],
                                                 unit: 'region',
                                                 unit_code_key: 'RGN19CD',
                                                 unit_code_value: '' })

      county.parent = region unless county.parent
      district.parent = county unless district.parent
      ward.parent = district

      ward.save! && ward
    end
  end
end
