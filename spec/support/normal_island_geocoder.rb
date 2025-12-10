# frozen_string_literal: true

# Normal Island Geocoder Stubs
# Fictional geography for testing - uses "NO" country code (Normal Island)
#
# Geography hierarchy:
# Country: Normal Island (NO)
# ├── Region: Northvale
# │   └── County: Greater Millbrook
# │       ├── District: Millbrook
# │       │   ├── Ward: Riverside (NOMB 1RS)
# │       │   ├── Ward: Oldtown (NOMB 2OT)
# │       │   ├── Ward: Greenfield (NOMB 3GF)
# │       │   └── Ward: Harbourside (NOMB 4HS)
# │       └── District: Ashdale
# │           ├── Ward: Hillcrest (NOAD 1HC)
# │           └── Ward: Valleyview (NOAD 2VV)
# └── Region: Southmere
#     └── County: Coastshire
#         └── District: Seaview
#             ├── Ward: Cliffside (NOSV 1CL)
#             └── Ward: Beachfront (NOSV 2BF)

Geocoder.configure(lookup: :test, ip_lookup: :test)

# Riverside Ward - Millbrook District
Geocoder::Lookup::Test.add_stub(
  'NOMB 1RS', [
    { 'postcode' => 'NOMB 1RS',
      'quality' => 1,
      'eastings' => 100_000,
      'northings' => 200_000,
      'country' => 'Normal Island',
      'longitude' => -1.5,
      'latitude' => 53.5,
      'region' => 'Northvale',
      'admin_district' => 'Millbrook',
      'admin_county' => 'Greater Millbrook',
      'admin_ward' => 'Riverside',
      'codes' => {
        'admin_district' => 'NO3000001',
        'admin_county' => 'NO2000001',
        'admin_ward' => 'NO4000001'
      } }
  ]
)

# Oldtown Ward - Millbrook District
Geocoder::Lookup::Test.add_stub(
  'NOMB 2OT', [
    { 'postcode' => 'NOMB 2OT',
      'quality' => 1,
      'eastings' => 100_500,
      'northings' => 200_500,
      'country' => 'Normal Island',
      'longitude' => -1.48,
      'latitude' => 53.52,
      'region' => 'Northvale',
      'admin_district' => 'Millbrook',
      'admin_county' => 'Greater Millbrook',
      'admin_ward' => 'Oldtown',
      'codes' => {
        'admin_district' => 'NO3000001',
        'admin_county' => 'NO2000001',
        'admin_ward' => 'NO4000002'
      } }
  ]
)

# Greenfield Ward - Millbrook District
Geocoder::Lookup::Test.add_stub(
  'NOMB 3GF', [
    { 'postcode' => 'NOMB 3GF',
      'quality' => 1,
      'eastings' => 101_000,
      'northings' => 201_000,
      'country' => 'Normal Island',
      'longitude' => -1.46,
      'latitude' => 53.54,
      'region' => 'Northvale',
      'admin_district' => 'Millbrook',
      'admin_county' => 'Greater Millbrook',
      'admin_ward' => 'Greenfield',
      'codes' => {
        'admin_district' => 'NO3000001',
        'admin_county' => 'NO2000001',
        'admin_ward' => 'NO4000003'
      } }
  ]
)

# Harbourside Ward - Millbrook District
Geocoder::Lookup::Test.add_stub(
  'NOMB 4HS', [
    { 'postcode' => 'NOMB 4HS',
      'quality' => 1,
      'eastings' => 99_500,
      'northings' => 199_500,
      'country' => 'Normal Island',
      'longitude' => -1.52,
      'latitude' => 53.48,
      'region' => 'Northvale',
      'admin_district' => 'Millbrook',
      'admin_county' => 'Greater Millbrook',
      'admin_ward' => 'Harbourside',
      'codes' => {
        'admin_district' => 'NO3000001',
        'admin_county' => 'NO2000001',
        'admin_ward' => 'NO4000004'
      } }
  ]
)

# Hillcrest Ward - Ashdale District
Geocoder::Lookup::Test.add_stub(
  'NOAD 1HC', [
    { 'postcode' => 'NOAD 1HC',
      'quality' => 1,
      'eastings' => 105_000,
      'northings' => 205_000,
      'country' => 'Normal Island',
      'longitude' => -1.4,
      'latitude' => 53.6,
      'region' => 'Northvale',
      'admin_district' => 'Ashdale',
      'admin_county' => 'Greater Millbrook',
      'admin_ward' => 'Hillcrest',
      'codes' => {
        'admin_district' => 'NO3000002',
        'admin_county' => 'NO2000001',
        'admin_ward' => 'NO4000005'
      } }
  ]
)

# Valleyview Ward - Ashdale District
Geocoder::Lookup::Test.add_stub(
  'NOAD 2VV', [
    { 'postcode' => 'NOAD 2VV',
      'quality' => 1,
      'eastings' => 106_000,
      'northings' => 206_000,
      'country' => 'Normal Island',
      'longitude' => -1.38,
      'latitude' => 53.62,
      'region' => 'Northvale',
      'admin_district' => 'Ashdale',
      'admin_county' => 'Greater Millbrook',
      'admin_ward' => 'Valleyview',
      'codes' => {
        'admin_district' => 'NO3000002',
        'admin_county' => 'NO2000001',
        'admin_ward' => 'NO4000006'
      } }
  ]
)

# Cliffside Ward - Seaview District (Southmere Region)
Geocoder::Lookup::Test.add_stub(
  'NOSV 1CL', [
    { 'postcode' => 'NOSV 1CL',
      'quality' => 1,
      'eastings' => 150_000,
      'northings' => 150_000,
      'country' => 'Normal Island',
      'longitude' => -0.5,
      'latitude' => 52.0,
      'region' => 'Southmere',
      'admin_district' => 'Seaview',
      'admin_county' => 'Coastshire',
      'admin_ward' => 'Cliffside',
      'codes' => {
        'admin_district' => 'NO3000003',
        'admin_county' => 'NO2000002',
        'admin_ward' => 'NO4000007'
      } }
  ]
)

# Beachfront Ward - Seaview District (Southmere Region)
Geocoder::Lookup::Test.add_stub(
  'NOSV 2BF', [
    { 'postcode' => 'NOSV 2BF',
      'quality' => 1,
      'eastings' => 151_000,
      'northings' => 151_000,
      'country' => 'Normal Island',
      'longitude' => -0.48,
      'latitude' => 52.02,
      'region' => 'Southmere',
      'admin_district' => 'Seaview',
      'admin_county' => 'Coastshire',
      'admin_ward' => 'Beachfront',
      'codes' => {
        'admin_district' => 'NO3000003',
        'admin_county' => 'NO2000002',
        'admin_ward' => 'NO4000008'
      } }
  ]
)

# Invalid/unknown postcode stub (empty result)
Geocoder::Lookup::Test.add_stub('NOXX 0XX', [])

# Postcode without matching neighbourhood in database
Geocoder::Lookup::Test.add_stub(
  'NOZZ 9ZZ', [
    { 'postcode' => 'NOZZ 9ZZ',
      'quality' => 1,
      'eastings' => 999_000,
      'northings' => 999_000,
      'country' => 'Normal Island',
      'longitude' => 0.0,
      'latitude' => 50.0,
      'region' => 'Unknown Region',
      'admin_district' => 'Unknown District',
      'admin_county' => 'Unknown County',
      'admin_ward' => 'Unknown Ward',
      'codes' => {
        'admin_district' => 'NO9999999',
        'admin_county' => 'NO9999999',
        'admin_ward' => 'NO9999999'
      } }
  ]
)
