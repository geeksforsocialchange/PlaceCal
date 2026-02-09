# frozen_string_literal: true

require_relative 'normal_island/uk_postcode_extension'

# Normal Island - Fictional Geography for Testing and Development
#
# This module provides consistent fictional geographic data that can be used
# by both test factories and development seeds, ensuring alignment between
# test and development environments.
#
# Geography hierarchy:
# Country: Normal Island (ZZ - user-assigned ISO 3166 code)
# ├── Region: Northvale
# │   └── County: Greater Millbrook
# │       ├── District: Millbrook
# │       │   ├── Ward: Riverside
# │       │   ├── Ward: Oldtown
# │       │   ├── Ward: Greenfield
# │       │   └── Ward: Harbourside
# │       └── District: Ashdale
# │           ├── Ward: Hillcrest
# │           └── Ward: Valleyview
# └── Region: Southmere
#     └── County: Coastshire
#         └── District: Seaview
#             ├── Ward: Cliffside
#             └── Ward: Beachfront

module NormalIsland
  # Country
  COUNTRY = {
    name: 'Normal Island',
    unit: 'country',
    unit_code_key: 'ZZ00CD',
    unit_code_value: 'ZZ0000001'
  }.freeze

  # Regions
  REGIONS = {
    northvale: {
      name: 'Northvale',
      unit: 'region',
      unit_code_key: 'ZZ00RG',
      unit_code_value: 'ZZ1000001'
    },
    southmere: {
      name: 'Southmere',
      unit: 'region',
      unit_code_key: 'ZZ00RG',
      unit_code_value: 'ZZ1000002'
    }
  }.freeze

  # Counties
  COUNTIES = {
    greater_millbrook: {
      name: 'Greater Millbrook',
      unit: 'county',
      unit_code_key: 'ZZ00CT',
      unit_code_value: 'ZZ2000001',
      parent_region: :northvale
    },
    coastshire: {
      name: 'Coastshire',
      unit: 'county',
      unit_code_key: 'ZZ00CT',
      unit_code_value: 'ZZ2000002',
      parent_region: :southmere
    }
  }.freeze

  # Districts
  DISTRICTS = {
    millbrook: {
      name: 'Millbrook',
      unit: 'district',
      unit_code_key: 'ZZ00DT',
      unit_code_value: 'ZZ3000001',
      parent_county: :greater_millbrook
    },
    ashdale: {
      name: 'Ashdale',
      unit: 'district',
      unit_code_key: 'ZZ00DT',
      unit_code_value: 'ZZ3000002',
      parent_county: :greater_millbrook
    },
    seaview: {
      name: 'Seaview',
      unit: 'district',
      unit_code_key: 'ZZ00DT',
      unit_code_value: 'ZZ3000003',
      parent_county: :coastshire
    }
  }.freeze

  # Wards
  WARDS = {
    riverside: {
      name: 'Riverside',
      unit: 'ward',
      unit_code_key: 'ZZ00WD',
      unit_code_value: 'ZZ4000001',
      parent_district: :millbrook,
      postcode: 'ZZMB 1RS'
    },
    oldtown: {
      name: 'Oldtown',
      unit: 'ward',
      unit_code_key: 'ZZ00WD',
      unit_code_value: 'ZZ4000002',
      parent_district: :millbrook,
      postcode: 'ZZMB 2OT'
    },
    greenfield: {
      name: 'Greenfield',
      unit: 'ward',
      unit_code_key: 'ZZ00WD',
      unit_code_value: 'ZZ4000003',
      parent_district: :millbrook,
      postcode: 'ZZMB 3GF'
    },
    harbourside: {
      name: 'Harbourside',
      unit: 'ward',
      unit_code_key: 'ZZ00WD',
      unit_code_value: 'ZZ4000004',
      parent_district: :millbrook,
      postcode: 'ZZMB 4HS'
    },
    hillcrest: {
      name: 'Hillcrest',
      unit: 'ward',
      unit_code_key: 'ZZ00WD',
      unit_code_value: 'ZZ4000005',
      parent_district: :ashdale,
      postcode: 'ZZAD 1HC'
    },
    valleyview: {
      name: 'Valleyview',
      unit: 'ward',
      unit_code_key: 'ZZ00WD',
      unit_code_value: 'ZZ4000006',
      parent_district: :ashdale,
      postcode: 'ZZAD 2VV'
    },
    cliffside: {
      name: 'Cliffside',
      unit: 'ward',
      unit_code_key: 'ZZ00WD',
      unit_code_value: 'ZZ4000007',
      parent_district: :seaview,
      postcode: 'ZZSV 1CL'
    },
    beachfront: {
      name: 'Beachfront',
      unit: 'ward',
      unit_code_key: 'ZZ00WD',
      unit_code_value: 'ZZ4000008',
      parent_district: :seaview,
      postcode: 'ZZSV 2BF'
    }
  }.freeze

  # Postcodes - mapping postcode to ward key
  POSTCODES = {
    'ZZMB 1RS' => :riverside,
    'ZZMB 2OT' => :oldtown,
    'ZZMB 3GF' => :greenfield,
    'ZZMB 4HS' => :harbourside,
    'ZZAD 1HC' => :hillcrest,
    'ZZAD 2VV' => :valleyview,
    'ZZSV 1CL' => :cliffside,
    'ZZSV 2BF' => :beachfront
  }.freeze

  # Sample addresses for each ward
  ADDRESSES = {
    riverside: {
      street_address: '1 River Road',
      postcode: 'ZZMB 1RS',
      latitude: 53.5,
      longitude: -1.5
    },
    oldtown: {
      street_address: '10 Heritage Lane',
      postcode: 'ZZMB 2OT',
      latitude: 53.52,
      longitude: -1.48
    },
    greenfield: {
      street_address: '25 Park Avenue',
      postcode: 'ZZMB 3GF',
      latitude: 53.54,
      longitude: -1.46
    },
    harbourside: {
      street_address: '42 Dock Street',
      postcode: 'ZZMB 4HS',
      latitude: 53.48,
      longitude: -1.52
    },
    hillcrest: {
      street_address: '15 Summit Drive',
      postcode: 'ZZAD 1HC',
      latitude: 53.6,
      longitude: -1.4
    },
    valleyview: {
      street_address: '8 Valley Road',
      postcode: 'ZZAD 2VV',
      latitude: 53.62,
      longitude: -1.38
    },
    cliffside: {
      street_address: '3 Cliff Walk',
      postcode: 'ZZSV 1CL',
      latitude: 52.0,
      longitude: -0.5
    },
    beachfront: {
      street_address: '20 Promenade',
      postcode: 'ZZSV 2BF',
      latitude: 52.02,
      longitude: -0.48
    }
  }.freeze

  # Sample partners
  PARTNERS = {
    riverside_community_hub: {
      name: 'Riverside Community Hub',
      summary: 'A welcoming community centre serving the Riverside ward',
      ward: :riverside
    },
    oldtown_library: {
      name: 'Oldtown Library',
      summary: 'Historic library with modern community services',
      ward: :oldtown
    },
    greenfield_youth_centre: {
      name: 'Greenfield Youth Centre',
      summary: 'Youth services and activities for young people',
      ward: :greenfield
    },
    harbourside_arts_centre: {
      name: 'Harbourside Arts Centre',
      summary: 'Arts venue with gallery, theatre, and workshops',
      ward: :harbourside
    },
    ashdale_sports_club: {
      name: 'Ashdale Sports Club',
      summary: 'Multi-sport facility serving Ashdale district',
      ward: :hillcrest
    },
    coastline_wellness_centre: {
      name: 'Coastline Wellness Centre',
      summary: 'Health and wellness services by the sea',
      ward: :cliffside
    }
  }.freeze

  # Sample sites
  SITES = {
    normal_island_central: {
      name: 'Normal Island Central',
      slug: 'default-site',
      tagline: 'Community events across Normal Island',
      country: true
    },
    normal_island_country: {
      name: 'Normal Island (country)',
      slug: 'normal-island',
      tagline: 'Everything happening across Normal Island',
      country: true
    },
    coastshire_county: {
      name: 'Coastshire (county)',
      slug: 'coastshire',
      tagline: 'Events and activities on the coast',
      county: :coastshire
    },
    millbrook_district: {
      name: 'Millbrook (district)',
      slug: 'millbrook',
      tagline: 'What\'s on in Millbrook',
      district: :millbrook
    }
  }.freeze

  # Sample users
  USERS = {
    root_admin: {
      email: 'admin@normalcal.org',
      first_name: 'Admin',
      last_name: 'User',
      role: 'root'
    },
    millbrook_admin: {
      email: 'millbrook@normalcal.org',
      first_name: 'Mill',
      last_name: 'Brook',
      role: 'neighbourhood_admin'
    },
    riverside_partner_admin: {
      email: 'riverside@normalcal.org',
      first_name: 'River',
      last_name: 'Side',
      role: 'partner_admin'
    }
  }.freeze

  # Tags
  TAGS = {
    categories: [
      { name: 'Health & Wellbeing', type: 'Category' },
      { name: 'Arts & Culture', type: 'Category' },
      { name: 'Sports & Fitness', type: 'Category' },
      { name: 'Education & Learning', type: 'Category' },
      { name: 'Community Events', type: 'Category' }
    ],
    facilities: [
      { name: 'Wheelchair Accessible', type: 'Facility' },
      { name: 'Parking Available', type: 'Facility' },
      { name: 'Child Friendly', type: 'Facility' },
      { name: 'Hearing Loop', type: 'Facility' }
    ],
    partnerships: [
      { name: 'Millbrook Together', type: 'Partnership' },
      { name: 'Coastal Alliance', type: 'Partnership' }
    ]
  }.freeze

  class << self
    # Get the full hierarchy path for a ward
    def ward_hierarchy(ward_key)
      ward = WARDS[ward_key]
      district = DISTRICTS[ward[:parent_district]]
      county = COUNTIES[district[:parent_county]]
      region = REGIONS[county[:parent_region]]

      {
        country: COUNTRY,
        region: region,
        county: county,
        district: district,
        ward: ward
      }
    end

    # Get ward by postcode
    def ward_for_postcode(postcode)
      ward_key = POSTCODES[postcode]
      ward_key ? WARDS[ward_key] : nil
    end

    # Get address data for a ward
    def address_for_ward(ward_key)
      ADDRESSES[ward_key]
    end
  end
end
