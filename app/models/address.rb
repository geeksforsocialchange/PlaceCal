# frozen_string_literal: true

# app/models/address.rb
class Address < ApplicationRecord
  geocoded_by :full_address

  POSTCODE_REGEX = /\s*((GIR\s*0AA)|((([A-PR-UWYZ][0-9]{1,2})|(([A-PR-UWYZ][A-HK-Y][0-9]{1,2})|(([A-PR-UWYZ][0-9][A-HJKSTUW])|([A-PR-UWYZ][A-HK-Y][0-9][ABEHMNPRVWXY]))))\s*[0-9][ABD-HJLNP-UW-Z]{2}))\s*/i

  validates :street_address, :postcode, :country_code, presence: true
  after_validation :geocode

  has_many :places
  has_many :events

  scope :find_by_street_or_postcode, lambda { |street, postcode|
    where(street_address: street).or(where(postcode: postcode))
  }

  def full_address
    [
      street_address,
      street_address2,
      street_address3,
      city,
      postcode,
      country_code
    ].reject(&:blank?).join(', ')
  end

  alias to_s full_address

  class << self
    # Components - Array containing parts of an event's location field
    def search(components, postcode)
      @address = Address.where(street_address: components).first
      if postcode && postcode.length >= 6 # Minimum length of a full postal code
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
      begin
        address = Address.new(street_address: components[0],
                              street_address2: components[1],
                              street_address3: components[2],
                              postcode: postcode)
        address.save!
        address
      rescue
        puts address
        Rails.logger.debug address
      end
    end
  end
end
