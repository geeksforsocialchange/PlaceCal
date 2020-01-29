# frozen_string_literal: true

FactoryBot.define do
  factory :partner do
    sequence(:name) do |n|
      "Community Group #{n}"
    end

    public_name { 'Partner Contact Name' }
    public_email { 'contact@communitygroup.org' }
    public_phone { '0161 0000000' }

    partner_email { 'admin@communitygroup.org' }
    partner_name { 'Addy Minny Strator' }
    partner_phone { '0161 0000001' }

    short_description { 'A cool garden centre' }
    url { 'http://example.com' }

    address

    after(:build) { |partner| partner.tags = [create(:tag)] }
    # image nil

    factory :ashton_partner, class: 'Partner' do
      association :address, factory: :ashton_address
    end

    opening_times { "[\r\n  {\r\n    \"@type\": \"OpeningHoursSpecification\",\r\n    \"closes\": \"20:00:00\",\r\n    \"dayOfWeek\": \"http://schema.org/Monday\",\r\n    \"opens\": \"09:00:00\"\r\n  },\r\n  {\r\n    \"@type\": \"OpeningHoursSpecification\",\r\n    \"closes\": \"17:00:00\",\r\n    \"dayOfWeek\": \"http://schema.org/Tuesday\",\r\n    \"opens\": \"09:00:00\"\r\n  },\r\n  {\r\n    \"@type\": \"OpeningHoursSpecification\",\r\n    \"closes\": \"17:00:00\",\r\n    \"dayOfWeek\": \"http://schema.org/Wednesday\",\r\n    \"opens\": \"09:00:00\"\r\n  },\r\n  {\r\n    \"@type\": \"OpeningHoursSpecification\",\r\n    \"closes\": \"17:00:00\",\r\n    \"dayOfWeek\": \"http://schema.org/Thursday\",\r\n    \"opens\": \"09:00:00\"\r\n  },\r\n  {\r\n    \"@type\": \"OpeningHoursSpecification\",\r\n    \"closes\": \"17:00:00\",\r\n    \"dayOfWeek\": \"http://schema.org/Friday\",\r\n    \"opens\": \"09:00:00\"\r\n  },\r\n  {\r\n    \"@type\": \"OpeningHoursSpecification\",\r\n    \"closes\": \"13:00:00\",\r\n    \"dayOfWeek\": \"http://schema.org/Saturday\",\r\n    \"opens\": \"09:00:00\"\r\n  }\r\n]" }

    factory :place do
      sequence(:name) do |n|
        "Community Venue #{n}"
      end

      public_name { 'Place Contact Name' }
      public_email { 'contact@venue.org' }
    end
  end

end
