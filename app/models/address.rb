# frozen_string_literal: true

# app/models/address.rb
class Address < ApplicationRecord
  # Geocoding with postcodes.io
  # Only postcode changes will change the result that postodes.io returns.
  # (do this first)
  validate :geocode_with_ward, if: ->(obj) { obj.postcode_changed? }

  validates :street_address, :country_code, presence: true
  validates :postcode, presence: true, postcode: true

  has_many :events
  has_many :partners
  has_many :calendars

  belongs_to :neighbourhood, optional: true

  scope :find_by_street_or_postcode, lambda { |street, postcode|
    where(street_address: street).or(where(postcode: postcode))
  }

  def postcode=(str)
    super(UKPostcode.parse(str).to_s)
  end

  def prepend_room_number(room_number_string)
    street_address3 = street_address2
    street_address2 = street_address
    street_address = room_number_string
    self
  end

  def first_address_line
    street_address
  end

  # Needed for schema.org outputs as streetAddress
  def full_street_address
    [street_address,
     street_address2,
     street_address3].compact_blank.join(', ')
  end

  def other_address_lines
    [street_address2,
     street_address3,
     city,
     postcode].compact_blank
  end

  def all_address_lines
    [street_address,
     street_address2,
     street_address3,
     city,
     postcode].compact_blank
  end

  def last_line_of_address
    all_address_lines[-2]
  end

  def to_s
    all_address_lines.join(', ')
  end

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

  class << self
    # location - The raw location field
    # components - Array containing parts of an event's location field, excluding the postcode.
    def search(_location, components, postcode)
      return nil if components.empty?

      # try by street name string match
      address = Address.find_by('lower(street_address) IN (?)', components.map(&:downcase))
      return address if address

      ukpc = UKPostcode.parse(postcode.to_s)

      if ukpc.full_valid?
        address = Address.find_by(postcode: ukpc.to_s)
        return address if address
      end

      begin
        # now just create one
        Address.build_from_components(components, postcode)
      rescue ActiveRecord::RecordNotFound
        # This 'solution' makes it so if an address is provided to us that
        # does not map cleanly on to our neighbourhood table then we simply
        # consider that a failed look up. In practice we should do more to
        # normalize data both coming from Postcodes.io and our UK government
        # ward dataset
      end
    end

    def build_from_components(components, postcode)
      return if components.blank?

      address = Address.new(
        street_address: components[0]&.strip,
        street_address2: components[1]&.strip,
        street_address3: components[2]&.strip,
        postcode: postcode
      )
      address if address.save
    end
  end
end
