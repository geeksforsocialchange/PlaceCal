# frozen_string_literal: true

FactoryBot.define do
  factory(:address) do
    street_address { '123 Moss Ln E' }
    street_address2 { 'Manchester' }
    city { 'Manchester' }
    country_code { 'UK' }
    latitude { 53.4651064 }
    longitude { -2.2484797 }
    postcode { 'M15 5DD' }

    after :create do |address|
      parent = create(:neighbourhood_district)
      address.neighbourhood.parent = parent
      address.neighbourhood.save
      parent.save

      is_childed = parent.children.map(&:subtree).flatten.include?(address.neighbourhood)
      puts "Address neighbourhood is childed: #{is_childed}"
      puts "Address parental ID: #{parent.id}; Child ID: #{address.neighbourhood.id}"
    end
  end

  factory :ashton_address, class: 'Address' do
    street_address { 'St Damians School' }
    street_address2 { 'Ashton-under-Lyne' }
    city { 'Tameside' }
    country_code { 'UK' }
    latitude { 53.509207 }
    longitude { -2.077027 }
    postcode { 'OL6 8BH' }

    association :neighbourhood, factory: :ashton_neighbourhood
  end
end
