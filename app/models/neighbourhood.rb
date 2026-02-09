# frozen_string_literal: true

class Neighbourhood < ApplicationRecord
  # WARNING: this must be updated for every new ONS dataset
  #    see /lib/tasks/neighbourhoods.rake
  LATEST_RELEASE_DATE = DateTime.new(2023, 5).freeze

  # Level constants (1=ward, 5=country)
  # Used for generic level abstraction across different locales
  LEVELS = {
    ward: 1,
    district: 2,
    county: 3,
    region: 4,
    country: 5
  }.freeze

  LEVEL_NAMES = LEVELS.invert.freeze

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

  has_many :addresses, dependent: :nullify
  has_many :address_partners,
           through: :addresses,
           source: :partners,
           class_name: 'Partner'

  # validates :unit_code_value, presence: true, uniqueness: true

  # validates :name, presence: true
  validates :unit_code_value,
            length: { is: 9 },
            allow_blank: true

  before_update :inject_parent_name_field

  scope :latest_release, -> { where release_date: LATEST_RELEASE_DATE }
  scope :at_level, ->(level) { where(level: level) }
  scope :countries, -> { where(level: 5) }
  scope :regions, -> { where(level: 4) }
  scope :counties, -> { where(level: 3) }
  scope :districts, -> { where(level: 2) }
  scope :wards, -> { where(level: 1) }

  def partners
    (service_area_partners + address_partners).uniq
  end

  def legacy_neighbourhood?
    release_date < Neighbourhood::LATEST_RELEASE_DATE
  end

  def shortname
    if name_abbr.present?
      name_abbr
    elsif name.present?
      name
    else
      '[not set]'
    end
  end

  def contextual_name
    # "Wardname, Countryname (Region)"
    return "#{shortname}, #{parent_name} (#{unit.titleize})" if parent_name

    # "Wardname (Region)"
    "#{shortname} (#{unit&.titleize})"
  end

  def fullname
    if name.present?
      name
    elsif name_abbr.present?
      name_abbr
    else
      '[not set]'
    end
  end

  # give us a name we can use for the abbreviated name even if
  # such a thing does not exist
  #
  # == Parameters: none
  #
  # == Returns
  #   A string of the name
  def abbreviated_name
    name_abbr.presence || name
  end

  # normalize abbreviated names (usually coming from calendar
  #   importer)
  #
  # == Parameters:
  # value::
  #   A string with the name value, or a blank string, or nil
  #
  # == Returns
  #   The input value normalized as a string or nil
  def name_abbr=(value)
    value = value.to_s.strip

    self['name_abbr'] = value.presence
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

  def name_from_badge_zoom(badge_zoom_level)
    badge_zoom_level == 'district' ? district&.shortname : shortname
  end

  # Returns the localized name for this level (e.g., "Ward", "District")
  def level_name
    LEVEL_NAMES[level]&.to_s
  end

  # Full hierarchy path as array of ancestors (from country down to self)
  def hierarchy_path
    [*ancestors.order(:ancestry), self]
  end

  # Full hierarchy as formatted string
  # @param separator [String] separator between levels (default: ', ')
  # @return [String] e.g., "England, South East, East Sussex, Wealden, Uckfield North"
  def full_hierarchy_name(separator: ', ')
    hierarchy_path.map(&:shortname).join(separator)
  end

  # Check if this neighbourhood has children with actual data
  # Used for smart-skip in cascading pickers
  def populated_children?
    children.where.not(name: [nil, '']).latest_release.exists?
  end

  # Refresh cached partners_count for this neighbourhood
  def refresh_partners_count!
    return unless persisted?

    # Use the same logic as partners method to avoid double-counting
    count = partners.count
    update_column(:partners_count, count) # rubocop:disable Rails/SkipsModelValidations
  end

  class << self
    def find_from_postcodesio_response(res)
      ons_id = res['codes']['admin_ward']
      Neighbourhood.where(unit_code_value: ons_id).first
    end

    # Refresh cached partners_count for all neighbourhoods
    # Run periodically or after bulk partner changes
    def refresh_partners_count!
      connection.execute(<<~SQL.squish)
        UPDATE neighbourhoods SET partners_count = (
          SELECT COUNT(*) FROM (
            SELECT DISTINCT p.id
            FROM addresses a
            JOIN partners p ON p.address_id = a.id
            WHERE a.neighbourhood_id = neighbourhoods.id
            UNION
            SELECT DISTINCT sa.partner_id
            FROM service_areas sa
            WHERE sa.neighbourhood_id = neighbourhoods.id
          ) AS unique_partners
        )
      SQL
    end

    def find_latest_neighbourhoods_maybe_with_legacy_neighbourhoods(scope, legacy_neighbourhoods)
      scope = scope
              .where('name is not null and name != \'\'')
              .latest_release

      scope = scope.or(where(id: legacy_neighbourhoods.pluck(:id))) if legacy_neighbourhoods.any?
      scope
    end
  end

  private

  def inject_parent_name_field
    self.parent_name = parent.name if parent
  end
end
