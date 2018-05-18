# frozen_string_literal: true

# app/models/address.rb
class Address < ApplicationRecord
  geocoded_by :full_address

  POSTCODE_REGEX = /\s*((GIR\s*0AA)|((([A-PR-UWYZ][0-9]{1,2})|(([A-PR-UWYZ][A-HK-Y][0-9]{1,2})|(([A-PR-UWYZ][0-9][A-HJKSTUW])|([A-PR-UWYZ][A-HK-Y][0-9][ABEHMNPRVWXY]))))\s*[0-9][ABD-HJLNP-UW-Z]{2}))\s*/i

  validates :street_address, :postcode, :country_code, presence: true
  after_validation :geocode, if: ->(obj) { obj.street_address_changed? || obj.street_address2_changed? || obj.postcode_changed? }

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

  class << self
    # location - The raw location field
    # components - Array containing parts of an event's location field
    def search(location, components, postcode)
      @address = Address.where(street_address: components).first

      if @address.blank? # try using coordinates to match address
        coordinates = Geocoder.coordinates(location)
        @address ||= Address.where(latitude: coordinates[0], longitude: coordinates[1]).first
      end

      # Search by postcode if it is minimum length of a full postal code
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
