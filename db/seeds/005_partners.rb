# frozen_string_literal: true

require_relative '../../lib/normal_island'

module SeedPartners
  LONG_TEXT = <<~LOREM_IPSUM
    Welcome to our community organisation! We provide a range of services and activities
    for local residents. Our friendly team is dedicated to supporting the community and
    creating opportunities for everyone to get involved.

    We offer regular events, workshops, and drop-in sessions throughout the week. Whether
    you're looking for social activities, learning opportunities, or just a friendly place
    to meet others, we're here for you.

    Our facilities are fully accessible and we welcome visitors of all ages and backgrounds.
    Please get in touch if you'd like to know more about what we do or how you can get involved.
  LOREM_IPSUM

  def self.run
    $stdout.puts 'Partners'

    # Create partners for each Normal Island location
    NormalIsland::PARTNERS.each do |key, data|
      ward = Neighbourhood.find_by(name: NormalIsland::WARDS[data[:ward]][:name])
      next unless ward

      address_data = NormalIsland::ADDRESSES[data[:ward]]

      address = Address.create!(
        street_address: address_data[:street_address],
        postcode: address_data[:postcode],
        latitude: address_data[:latitude],
        longitude: address_data[:longitude],
        neighbourhood: ward
      )

      partner = Partner.create!(
        name: data[:name],
        summary: data[:summary],
        description: LONG_TEXT,
        address: address
      )

      $stdout.puts "  Created partner: #{partner.name} (#{ward.name})"
    end
  end
end

SeedPartners.run
