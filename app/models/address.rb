# frozen_string_literal: true

class Address < ApplicationRecord
  # ==== Includes / Extends ====
  include NeighbourhoodCacheInvalidator

  # ==== Attributes ====
  attribute :city,            :string
  attribute :country_code,    :string, default: 'UK'
  attribute :latitude,        :float
  attribute :longitude,       :float
  attribute :postcode,        :string
  attribute :street_address,  :string
  attribute :street_address2, :string
  attribute :street_address3, :string

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
    where(street_address: street).or(where(postcode: postcode))
  }

  # ==== Callbacks ====
  after_commit :invalidate_neighbourhood_partners_count!, if: :neighbourhood_id_previously_changed?

  # ==== Class methods ====

  # Build and save an address from an array of street components.
  # @param components [Array<String>] up to 3 street address lines
  # @param postcode [String]
  # @return [Address, nil] persisted address, or nil if save fails
  def self.build_from_components(components, postcode)
    return if components.blank?

    address = Address.new(
      street_address: components[0],
      street_address2: components[1],
      street_address3: components[2],
      postcode: postcode
    )
    address.save ? address : nil
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

  # ==== Instance methods ====

  # Normalizes postcode via UKPostcode before saving.
  # @param str [String]
  # @return [String]
  def postcode=(str)
    super(UKPostcode.parse(str).to_s)
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
    res = Geocoder.search(postcode).first&.data
    if res.nil?
      errors.add :postcode, 'was not found'
      return
    end

    # There shouldn't be any wards that are outside our system, if there are we just fail.
    neighbourhood = Neighbourhood.find_from_postcodesio_response(res)
    if neighbourhood.nil?
      errors.add :postcode, 'has been found but could not be mapped to a neighbourhood at this time'
      return
    end

    self.neighbourhood = neighbourhood

    # Standardise the lat and lng for each postcode
    # Makes it easier to catch dupes
    self.longitude = res['longitude']
    self.latitude = res['latitude']
  end
end
