class Address < ApplicationRecord
  belongs_to :addressable, polymorphic: true

  geocoded_by :full_address

  after_validation :geocode


  def full_address
    [ :street_address, :street_address2, :street_address3, :city, :postcode ].join(', ')
  end
end
