# frozen_string_literal: true

class Neighbourhood < ApplicationRecord
  # ==== Includes / Extends ====
  has_ancestry
  extend Enumerize

  # ==== Constants ====

  # WARNING: this must be updated for every new ONS dataset
  #    see /lib/tasks/neighbourhoods.rake
  LATEST_RELEASE_DATE = DateTime.new(2024, 5).freeze

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

  # ==== Enums / Enumerize ====
  enumerize :unit,
            in: %i[ward district county region country],
            default: :ward
  # unit -- managed by enumerize, attribute declaration skipped

  # ==== Attributes ====
  # ancestry -- managed by Ancestry gem, attribute declaration skipped
  attribute :level,           :integer
  attribute :name,            :string
  attribute :name_abbr,       :string
  attribute :parent_name,     :string
  attribute :partners_count,  :integer, default: 0
  attribute :release_date,    :datetime
  attribute :unit_code_key,   :string, default: 'WD19CD'
  attribute :unit_code_value, :string
  attribute :unit_name,       :string

  # ==== Associations ====
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

  # ==== Validations ====
  # validates :unit_code_value, presence: true, uniqueness: true
  # validates :name, presence: true
  validates :level, inclusion: { in: LEVELS.values }, allow_nil: true
  validates :unit_code_value,
            length: { is: 9 },
            allow_blank: true

  # ==== Scopes ====
  scope :latest_release, -> { where release_date: LATEST_RELEASE_DATE }
  scope :at_level, ->(level) { where(level: level) }
  scope :countries, -> { where(level: 5) }
  scope :regions, -> { where(level: 4) }
  scope :counties, -> { where(level: 3) }
  scope :districts, -> { where(level: 2) }
  scope :wards, -> { where(level: 1) }

  # ==== Callbacks ====
  before_update :inject_parent_name_field

  # ==== Class methods ====

  class << self
    # @param res [Hash] parsed postcodes.io API response with 'codes' sub-hash
    # @return [Neighbourhood, nil] matching neighbourhood or nil
    def find_from_postcodesio_response(res)
      # Try ward first (most specific)
      ward_code = res.dig('codes', 'admin_ward')
      result = Neighbourhood.where(unit_code_value: ward_code).first if ward_code.present?
      return result if result

      # Fallback to district when ward code is from a newer ONS release
      # than what we have imported (e.g. boundary reviews that postcodes.io
      # has adopted but ONS hasn't published in their hierarchy files yet)
      district_code = res.dig('codes', 'admin_district')
      Neighbourhood.where(unit_code_value: district_code).first if district_code.present?
    end

    # Bulk-refresh cached partners_count for all neighbourhoods via SQL.
    # @return [void]
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

    # @param scope [ActiveRecord::Relation<Neighbourhood>] base query to filter
    # @param legacy_neighbourhoods [ActiveRecord::Relation<Neighbourhood>] old neighbourhoods to include
    # @return [ActiveRecord::Relation<Neighbourhood>]
    def find_latest_neighbourhoods_maybe_with_legacy_neighbourhoods(scope, legacy_neighbourhoods)
      scope = scope
              .where('name is not null and name != \'\'')
              .latest_release

      scope = scope.or(where(id: legacy_neighbourhoods.pluck(:id))) if legacy_neighbourhoods.any?
      scope
    end
  end

  # ==== Instance methods ====

  # @return [Array<Partner>] unique partners from address + service area associations
  def partners
    (service_area_partners + address_partners).uniq
  end

  # @return [Boolean] whether this neighbourhood predates the latest ONS release
  def legacy_neighbourhood?
    release_date < Neighbourhood::LATEST_RELEASE_DATE
  end

  # @return [String] abbreviated name, falling back to name or "[not set]"
  def shortname
    if name_abbr.present?
      name_abbr
    elsif name.present?
      name
    else
      '[not set]'
    end
  end

  # @return [String] name with parent and unit, e.g. "Hulme, Manchester (Ward)"
  def contextual_name
    # "Wardname, Countryname (Region)"
    return "#{shortname}, #{parent_name} (#{unit.titleize})" if parent_name

    # "Wardname (Region)"
    "#{shortname} (#{unit&.titleize})"
  end

  # @return [String] full name, falling back to abbreviation or "[not set]"
  def fullname
    if name.present?
      name
    elsif name_abbr.present?
      name_abbr
    else
      '[not set]'
    end
  end

  # @return [String] name_abbr if present, otherwise name
  def abbreviated_name
    name_abbr.presence || name
  end

  # Normalize abbreviated names (usually from calendar importer).
  # @param value [String, nil] raw name value
  # @return [String, nil] stripped value or nil if blank
  def name_abbr=(value)
    value = value.to_s.strip

    self['name_abbr'] = value.presence
  end

  # @return [Neighbourhood, nil] ancestor at district level
  def district
    ancestors.where(unit: 'district').first
  end

  # @return [Neighbourhood, nil] ancestor at county level
  def county
    ancestors.where(unit: 'county').first
  end

  # @return [Neighbourhood, nil] ancestor at region level
  def region
    ancestors.where(unit: 'region').first
  end

  # @return [Neighbourhood, nil] ancestor at country level
  def country
    ancestors.where(unit: 'country').first
  end

  # @param badge_zoom_level [String] 'ward' or 'district'
  # @return [String]
  def name_from_badge_zoom(badge_zoom_level)
    badge_zoom_level == 'district' ? district&.shortname : shortname
  end

  # @return [Symbol, nil] localized level name (e.g. :ward, :district)
  def level_name
    LEVEL_NAMES[level]&.to_s
  end

  # @return [Array<Neighbourhood>] ancestors from country down to self
  def hierarchy_path
    [*ancestors.order(:ancestry), self]
  end

  # Full hierarchy as formatted string
  # @param separator [String] separator between levels (default: ', ')
  # @return [String] e.g., "England, South East, East Sussex, Wealden, Uckfield North"
  def full_hierarchy_name(separator: ', ')
    hierarchy_path.map(&:shortname).join(separator)
  end

  # @return [Boolean] whether any children have data (for cascading pickers)
  def populated_children?
    children.where.not(name: [nil, '']).latest_release.exists?
  end

  # @return [void]
  def refresh_partners_count!
    return unless persisted?

    # Use the same logic as partners method to avoid double-counting
    count = partners.count
    update_column(:partners_count, count) # rubocop:disable Rails/SkipsModelValidations
  end

  private

  # ==== Private methods ====

  def inject_parent_name_field
    self.parent_name = parent.name if parent
  end
end
