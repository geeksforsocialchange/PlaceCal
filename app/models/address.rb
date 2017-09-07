class Address < ApplicationRecord

  geocoded_by :full_address

  validates :street_address, :postcode, :country_code, presence: true
  after_validation :geocode



  def full_address
    [ street_address, street_address2, street_address3, city, postcode, country_code ].reject(&:blank?).join(', ')
  end

  alias to_s full_address

end
