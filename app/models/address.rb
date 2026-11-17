# frozen_string_literal: true

# == Schema Information
#
# Table name: addresses
#
#  id               :bigint           not null, primary key
#  city             :string
#  country_code     :string           default("UK"), not null
#  latitude         :float
#  longitude        :float
#  postcode         :string           not null
#  street_address   :string           not null
#  street_address2  :string
#  street_address3  :string
#  neighbourhood_id :bigint
#
# Indexes
#
#  index_addresses_on_neighbourhood_id  (neighbourhood_id)
#
# Foreign Keys
#
#  fk_rails_...  (neighbourhood_id => neighbourhoods.id)
#
class Address < ApplicationRecord
  # ==== Includes / Extends ====
  include NeighbourhoodCacheInvalidator

  # Postcode lookup fields naming the town or wider area, which imported location text often repeats
  PLACE_NAME_FIELDS = %w[admin_district admin_county region country].freeze

  # ==== Attributes ====
  attribute :city,            :string
  attribute :country_code,    :string, default: 'UK'
  attribute :latitude,        :float
  attribute :longitude,       :float
  attribute :postcode,        :string
  attribute :street_address,  :string
  attribute :street_address2, :string
  attribute :street_address3, :string

  # Set for imported location text, whose later parts often repeat a place name the postcode lookup gives
  attr_accessor :drop_repeated_place_names

  auto_strip_attributes :street_address, :street_address2, :street_address3, :city, :postcode

  # ==== Associations ====
  has_many :events, dependent: :nullify
  has_many :partners, dependent: :nullify

  belongs_to :neighbourhood, optional: true

  # ==== Validations ====
  # Geocoding with postcodes.io
  # Only postcode changes will change the result that postodes.io returns.
  # (do this first)
  validate :geocode_with_ward, if: ->(obj) { obj.postcode_changed? }

  validates :street_address, :country_code, presence: true
  validates :postcode, presence: true, postcode: true

  # ==== Scopes ====
  scope :find_by_street_or_postcode, lambda { |street, postcode|
    where(street_address: street).or(where(postcode:))
  }

  # ==== Callbacks ====
  after_commit :invalidate_neighbourhood_partners_count!, if: :neighbourhood_id_previously_changed?

  # ==== Class methods ====

  # Build and save an address from an array of street components.
  # @param components [Array<String>] up to 3 street address lines; the second and third are dropped if they repeat a place name the postcode lookup gives
  # @param postcode [String]
  # @return [Address, nil] persisted address, or nil if save fails
  def self.build_from_components(components, postcode)
    build_from_components_with_reason(components, postcode).first
  end

  # Like build_from_components, but says why no address could be built.
  # @return [Array(Address, nil)] the saved address
  # @return [Array(nil, Symbol)] nil and one of :no_street, :no_postcode, :postcode_not_found, :lookup_unavailable, :outside_neighbourhoods
  def self.build_from_components_with_reason(components, postcode)
    return [nil, :no_street] if components.blank?
    return [nil, :no_postcode] if postcode.blank?

    address = Address.new(street_address: components[0], street_address2: components[1], street_address3: components[2], postcode:,
                          drop_repeated_place_names: true)
    address.save ? [address, nil] : [nil, address.unreadable_reason]
  end

  # Delete addresses not referenced by any partner or event.
  # @return [Integer] number of deleted rows
  def self.delete_orphaned!
    in_use_ids = Set.new(Partner.pluck(:address_id).compact) |
                 Set.new(Event.pluck(:address_id).compact)

    orphaned = where.not(id: in_use_ids)
    count = orphaned.count
    orphaned.in_batches(of: 1000).delete_all if count.positive?
    count
  end

  # @return [Symbol] why this unsaved address failed validation, in build_from_components_with_reason's terms
  def unreadable_reason
    return :no_street if errors.details[:street_address].any?

    case errors.details[:postcode].first&.dig(:error)
    when :not_found then :postcode_not_found
    when :lookup_unavailable then :lookup_unavailable
    when :unmapped then :outside_neighbourhoods
    else :no_postcode
    end
  end

  # ==== Instance methods ====

  # Normalizes postcode via UKPostcode before saving.
  # @param str [String]
  # @return [String]
  def postcode=(str)
    super(UKPostcode.parse(str).to_s)
  end

  # Same postcode and first street line, ignoring case, spacing and punctuation.
  # @param other [Address, nil]
  # @return [Boolean]
  def same_building_as?(other)
    return false if other.nil? || postcode.blank? || street_address.blank?

    squash = ->(text) { text.to_s.downcase.gsub(/[^a-z0-9]/, '') }
    squash.call(postcode) == squash.call(other.postcode) && squash.call(street_address) == squash.call(other.street_address)
  end

  # Shift existing street lines down and insert a room number as line 1.
  # @param room_number_string [String]
  # @return [Address] self
  def prepend_room_number(room_number_string)
    self.street_address3 = street_address2
    self.street_address2 = street_address
    self.street_address = room_number_string
    self
  end

  # @return [Array<String>] non-blank street address lines
  def street_lines
    [street_address, street_address2, street_address3].compact_blank
  end

  # @return [Boolean] true if all address fields are blank
  def missing_values?
    street_lines.empty? && city.blank? && postcode.blank?
  end

  # @return [String, nil]
  def first_address_line
    street_address
  end

  # @return [String] comma-joined street lines (for schema.org streetAddress)
  def full_street_address
    street_lines.join(', ')
  end

  # @return [Array<String>] all non-blank lines including city and postcode
  def all_address_lines
    [*street_lines, city, postcode].compact_blank
  end

  def to_s
    all_address_lines.join(', ')
  end

  # Schema.org PostalAddress node, shared by the partner and event JSON-LD
  # builders (PartnerJsonLd, EventJsonLd).
  # @return [Hash]
  def to_json_ld
    {
      '@type' => 'PostalAddress',
      'streetAddress' => full_street_address,
      'addressLocality' => city,
      'postalCode' => postcode,
      'addressCountry' => country_code
    }.compact
  end

  private

  # ==== Private methods ====

  # Set the (lat,lon) and neighbourhood from address data.
  #
  # This differs from calling the Geocoder::Store::ActiveRecord#geocode method
  # through an ActiveRecord callback because, as well as (lat,lon), we are
  # also setting the neighbourhood from the admin_ward value returned by
  # postcodes.io
  #
  # NOTE: Geocoder is not isolating us from geocoding-service implentation
  # details. We currently require the geocoding result to contain the key
  # 'admin_ward' from postcodes.io
  def geocode_with_ward
    res = PostcodeLookup.call(postcode)
    if res.nil?
      errors.add :postcode, :not_found
      return
    end

    # There shouldn't be any wards that are outside our system, if there are we just fail.
    neighbourhood = Neighbourhood.find_from_postcodesio_response(res)
    if neighbourhood.nil?
      errors.add :postcode, :unmapped
      return
    end

    self.neighbourhood = neighbourhood

    # Standardise the lat and lng for each postcode
    # Makes it easier to catch dupes
    self.longitude = res['longitude']
    self.latitude = res['latitude']

    # Existing addresses are backfilled via the addresses:backfill_city rake
    # task (see #3123).
    self.city = res['admin_district'] if city.blank?
    drop_lines_repeating_place_names(res) if drop_repeated_place_names
  rescue PostcodeLookup::Unavailable
    errors.add :postcode, :lookup_unavailable
  end

  # The first line is left alone so the address always keeps one
  def drop_lines_repeating_place_names(lookup)
    squash = ->(text) { text.to_s.squish.downcase }
    place_names = lookup.values_at(*PLACE_NAME_FIELDS).compact_blank.map(&squash)
    self.street_address2, self.street_address3 = [street_address2, street_address3].reject { |line| place_names.include?(squash.call(line)) }
  end
end
