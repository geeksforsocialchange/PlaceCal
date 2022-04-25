# frozen_string_literal: true

# app/models/address.rb
class Address < ApplicationRecord

  POSTCODE_REGEX = /\s*((GIR\s*0AA)|((([A-PR-UWYZ][0-9]{1,2})|(([A-PR-UWYZ][A-HK-Y][0-9]{1,2})|(([A-PR-UWYZ][0-9][A-HJKSTUW])|([A-PR-UWYZ][A-HK-Y][0-9][ABEHMNPRVWXY]))))\s*[0-9][ABD-HJLNP-UW-Z]{2}))\s*/i

  validates :street_address, :postcode, :country_code, presence: true
  validates :postcode, format: { with: POSTCODE_REGEX, message: 'is invalid' }

  # Geocoding with postcodes.io
  # Only postcode changes will change the result that postodes.io returns.
  after_validation :geocode_with_ward, if: ->(obj) { obj.postcode_changed? }

  # We want to be able to compare an arbitrary postcode with the address
  # postodes in the DB, so make sure all postcodes in the DB are in the same
  # format.
  before_save :standardise_postcode, if: ->(obj) { obj.postcode_changed? }

  has_many :events
  has_many :partners
  has_many :calendars

  belongs_to :neighbourhood, optional: true

  scope :find_by_street_or_postcode, lambda { |street, postcode|
    where(street_address: street).or(where(postcode: postcode))
  }

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
    [ street_address,
      street_address2,
      street_address3,
    ].reject(&:blank?).join(', ')
  end

  def other_address_lines
    [ street_address2,
      street_address3,
      city,
      postcode
    ].reject(&:blank?)
  end

  def all_address_lines
    [ street_address,
      street_address2,
      street_address3,
      city,
      postcode
    ].reject(&:blank?)
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
    return unless res

    # There shouldn't be any wards that are outside our system, if there are we just fail.
    neighbourhood = Neighbourhood.find_from_postcodesio_response(res)
    self.neighbourhood = neighbourhood

    # Standardise the lat and lng for each postcode
    # Makes it easier to catch dupes
    self.longitude = res['longitude']
    self.latitude = res['latitude']
  end

  def standardise_postcode
    self.postcode = self.class.standardised_postcode(postcode)
  end

  class << self
    # location - The raw location field
    # components - Array containing parts of an event's location field, excluding the postcode.
    def search(location, components, postcode)

      # try by street name string match
      address = Address.find_by('lower(street_address) IN (?)', components.map(&:downcase))
      return address if address

      # try by postcode
      postcode = standardised_postcode(postcode)

      if postcode && postcode.length >= 'A1 1AA'.length
        address = Address.find_by(postcode: postcode)
        return address if address
      end

      # now just create one
      Address.build_from_components(components, postcode)
    end

    def build_from_components(components, postcode)
      return if components.blank?

      address = Address.new(
        street_address:  components[0]&.strip,
        street_address2: components[1]&.strip,
        street_address3: components[2]&.strip,
        postcode:        postcode
      )
      address if address.save
    end

    # Define a standard postcode format so that postcode comparisons can be
    # made, including with postcode values the DB.
    # Standard format is ALL CAPS where the only whitespace is a single space
    # before the final three characters.
    def standardised_postcode(pc)
      return unless pc
      pc.gsub(/\s+/, "").strip.upcase.insert(-4, ' ')
    end
  end
end

__END__

the old Address.search tried to find an adress directly through the addresses table,
  matching by text first and then by postcode.
  If it found an address it would look to see if a partner existed at that address
  and return that partner.
  otherwise it would create a new address

How the event resolver works now is that place (partner) is derived explicitly in
  the resolver algorithm.
  this means that this method (on address) should only find-or-create an address

    def search(location, components, postcode)

      # Find the first Address whose first address line contains any one of the
      # address lines in the components argument. Case insensitive.
      address = Address.find_by('lower(street_address) IN (?)', components.map(&:downcase))

      # We were looking for an exact match of geocoding coordinates, but we are
      # now using postcodes.io exclusively so a postcode match is now
      # equivalent to a coordinate match.
      # if @address.blank?
      #   coordinates = Geocoder.coordinates(postcode)
      #   @address ||= Address.where(latitude: coordinates[0], longitude: coordinates[1]).first
      # end

      # Make the postcode comparible with postcodes in the DB.
      postcode = standardised_postcode(postcode)

      # Find address by postcode if postcode is long enough to be a valid.
      if ! address  &&  postcode  &&  postcode.length >= 'A1 1AA'.length
        address = Address.find_by(postcode: postcode)
      end

      if address
        partner = address.partners.first
        partner.present? ? [ :place_id, partner.id ] : [ :address_id, address.id ]
      else
        # Make a new address.
        address = Address.build_from_components(components, postcode)
        [ :address_id, address.try(:id) ]
      end
    end
