# frozen_string_literal: true

# app/models/address.rb
class Address < ApplicationRecord

  POSTCODE_REGEX = /\s*((GIR\s*0AA)|((([A-PR-UWYZ][0-9]{1,2})|(([A-PR-UWYZ][A-HK-Y][0-9]{1,2})|(([A-PR-UWYZ][0-9][A-HJKSTUW])|([A-PR-UWYZ][A-HK-Y][0-9][ABEHMNPRVWXY]))))\s*[0-9][ABD-HJLNP-UW-Z]{2}))\s*/i

  validates :street_address, :postcode, :country_code, presence: true

  # Geocoding with postcodes.io so only postcode changes will change the result
  after_validation :geocode_with_ward, if: ->(obj) { obj.postcode_changed? }

  has_many :places
  has_many :events
  has_many :partners
  has_many :calendars

  scope :find_by_street_or_postcode, lambda { |street, postcode|
    where(street_address: street).or(where(postcode: postcode))
  }

  def full_address
    [
      street_address,
      street_address2,
      street_address3,
      city,
      postcode
    ].reject(&:blank?).join(', ')
  end

  alias to_s full_address

  def geocode_with_ward
    # TODO? Is there any point using the Geocoder gem rather than writing
    # our own code to query postcodes.io given that using postcodes.io
    # now defines how we use Geocoder?
    # - Passing anything other than a postcode will cause Geocoder.search to
    #   return an empty array.
    # - We are accessing admin_ward directly through through
    #   Geocoder::Result::PostcodesIo#data hash.

    logger.warn("I have been CALLED!!!!!")
    logger.warn(postcode)

    geo = Geocoder.search(postcode).first&.data
    logger.warn(geo.inspect)

    if geo
      # write_attribute :longitude, geo['longitude']
      # write_attribute :latitude, geo['latitude']
      # write_attribute :admin_ward, geo['admin_ward']
      self.longitude= geo['longitude']
      self.latitude= geo['latitude']
      self.admin_ward= geo['admin_ward']
      logger.warn(self.inspect)
    end
  end

  class << self
    # location - The raw location field
    # components - Array containing parts of an event's location field, excluding the postcode.
    def search(location, components, postcode)

      # Find the first Address whose first address line contains any one of the
      # address lines in the components argument.
      @address = Address.where(street_address: components).first

      # We were looking for an exact match of geocoding coordinates, but we are
      # now using postcodes.io exclusively so a postcode match is now
      # equivalent to a coordinate match.
      # if @address.blank?
      #   coordinates = Geocoder.coordinates(postcode)
      #   @address ||= Address.where(latitude: coordinates[0], longitude: coordinates[1]).first
      # end

      # Search by postcode if it is minimum length of a full postal code
      # TODO? Are postcodes guaranteed to be in the same format? E.g A1 2BC
      # versus A12BC versus a12bc, all of which are valid.
      if postcode && postcode.length >= 6
        @address ||= Address.where(postcode: postcode).first
      end

      if @address.present?
        @place = @address.places.first
        @place.present? ? { place_id: @place.id } : { address_id: @address.id }
      else
        address = Address.build_from_components(components, postcode)
        { address_id: address.try(:id) }
      end
    end

    def build_from_components(components, postcode)
      return if components.blank?
      address = Address.new(street_address: components[0]&.strip,
                            street_address2: components[1]&.strip,
                            street_address3: components[2]&.strip,
                            postcode: postcode&.strip)
      address if address.save
    end
  end
end
