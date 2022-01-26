# frozen_string_literal: true

class Neighbourhood < ApplicationRecord
  has_ancestry
  has_many :sites_neighbourhoods, dependent: :destroy
  has_many :sites, through: :sites_neighbourhoods

  has_many :neighbourhoods_users, dependent: :destroy
  has_many :users, through: :neighbourhoods_users

  has_many :service_areas, dependent: :destroy
  has_many :service_area_partners,
    through: :service_areas,
    source: :partner,
    class_name: 'Partner'

  # validates :name, presence: true
  validates :unit_code_value,
            length: { is: 9 },
            allow_blank: true

  def shortname
    if name_abbr.present?
      name_abbr
    elsif name.present?
      name
    else
      "[not set]"
    end
  end

  def fullname
    if name.present?
      name 
    elsif name_abbr.present?
      name_abbr
    else
      "[not set]"
    end
  end

  def to_s
    "#{fullname} (#{unit})"
  end

  def district
    ancestors.where(unit: 'district').first
  end

  def county
    ancestors.where(unit: 'county').first
  end

  def region
    ancestors.where(unit: 'region').first
  end

  def country
    ancestors.where(unit: 'country').first
  end

  class << self
    def find_from_postcodesio_response(res)
      Neighbourhood.find_by!(unit: 'ward',
                             unit_code_key: 'WD19CD',
                             unit_code_value: res['codes']['admin_ward'],
                             unit_name: res['admin_ward'])
    end
  end
end
