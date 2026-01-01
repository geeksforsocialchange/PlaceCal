# frozen_string_literal: true

# Normal Island Geocoder Stubs
# Fictional geography for testing - uses "ZZ" user-assigned ISO 3166 code
#
# Geography hierarchy:
# Country: Normal Island (ZZ)
# ├── Region: Northvale
# │   └── County: Greater Millbrook
# │       ├── District: Millbrook
# │       │   ├── Ward: Riverside (ZZMB 1RS)
# │       │   ├── Ward: Oldtown (ZZMB 2OT)
# │       │   ├── Ward: Greenfield (ZZMB 3GF)
# │       │   └── Ward: Harbourside (ZZMB 4HS)
# │       └── District: Ashdale
# │           ├── Ward: Hillcrest (ZZAD 1HC)
# │           └── Ward: Valleyview (ZZAD 2VV)
# └── Region: Southmere
#     └── County: Coastshire
#         └── District: Seaview
#             ├── Ward: Cliffside (ZZSV 1CL)
#             └── Ward: Beachfront (ZZSV 2BF)

Geocoder.configure(lookup: :test, ip_lookup: :test)

# Riverside Ward - Millbrook District
Geocoder::Lookup::Test.add_stub(
  'ZZMB 1RS', [
    { 'postcode' => 'ZZMB 1RS',
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
        'admin_district' => 'ZZ3000001',
        'admin_county' => 'ZZ2000001',
        'admin_ward' => 'ZZ4000001'
      } }
  ]
)

# Oldtown Ward - Millbrook District
Geocoder::Lookup::Test.add_stub(
  'ZZMB 2OT', [
    { 'postcode' => 'ZZMB 2OT',
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
        'admin_district' => 'ZZ3000001',
        'admin_county' => 'ZZ2000001',
        'admin_ward' => 'ZZ4000002'
      } }
  ]
)

# Greenfield Ward - Millbrook District
Geocoder::Lookup::Test.add_stub(
  'ZZMB 3GF', [
    { 'postcode' => 'ZZMB 3GF',
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
        'admin_district' => 'ZZ3000001',
        'admin_county' => 'ZZ2000001',
        'admin_ward' => 'ZZ4000003'
      } }
  ]
)

# Harbourside Ward - Millbrook District
Geocoder::Lookup::Test.add_stub(
  'ZZMB 4HS', [
    { 'postcode' => 'ZZMB 4HS',
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
        'admin_district' => 'ZZ3000001',
        'admin_county' => 'ZZ2000001',
        'admin_ward' => 'ZZ4000004'
      } }
  ]
)

# Hillcrest Ward - Ashdale District
Geocoder::Lookup::Test.add_stub(
  'ZZAD 1HC', [
    { 'postcode' => 'ZZAD 1HC',
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
        'admin_district' => 'ZZ3000002',
        'admin_county' => 'ZZ2000001',
        'admin_ward' => 'ZZ4000005'
      } }
  ]
)

# Valleyview Ward - Ashdale District
Geocoder::Lookup::Test.add_stub(
  'ZZAD 2VV', [
    { 'postcode' => 'ZZAD 2VV',
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
        'admin_district' => 'ZZ3000002',
        'admin_county' => 'ZZ2000001',
        'admin_ward' => 'ZZ4000006'
      } }
  ]
)

# Cliffside Ward - Seaview District (Southmere Region)
Geocoder::Lookup::Test.add_stub(
  'ZZSV 1CL', [
    { 'postcode' => 'ZZSV 1CL',
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
        'admin_district' => 'ZZ3000003',
        'admin_county' => 'ZZ2000002',
        'admin_ward' => 'ZZ4000007'
      } }
  ]
)

# Beachfront Ward - Seaview District (Southmere Region)
Geocoder::Lookup::Test.add_stub(
  'ZZSV 2BF', [
    { 'postcode' => 'ZZSV 2BF',
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
        'admin_district' => 'ZZ3000003',
        'admin_county' => 'ZZ2000002',
        'admin_ward' => 'ZZ4000008'
      } }
  ]
)

# Invalid/unknown postcode stub (empty result)
Geocoder::Lookup::Test.add_stub('ZZXX 0XX', [])

# Postcode without matching neighbourhood in database
Geocoder::Lookup::Test.add_stub(
  'ZZUN 9ZZ', [
    { 'postcode' => 'ZZUN 9ZZ',
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
        'admin_district' => 'ZZ9999999',
        'admin_county' => 'ZZ9999999',
        'admin_ward' => 'ZZ9999999'
      } }
  ]
)

# Manchester postcodes (from VCR cassettes)
# These are real UK postcodes used in the recorded API responses
['M15 5DD', 'M155DD', 'M16 7BA', 'M167BA', 'M15 6BX', 'M156BX'].each do |postcode|
  Geocoder::Lookup::Test.add_stub(
    postcode, [
      { 'postcode' => postcode.gsub(/\s+/, ' ').strip,
        'quality' => 1,
        'eastings' => 384_000,
        'northings' => 397_000,
        'country' => 'England',
        'longitude' => -2.2426,
        'latitude' => 53.4668,
        'region' => 'North West',
        'admin_district' => 'Manchester',
        'admin_county' => 'Greater Manchester',
        'admin_ward' => 'Hulme',
        'codes' => {
          'admin_district' => 'E08000003',
          'admin_county' => 'E11000001',
          'admin_ward' => 'E05011368'
        } }
    ]
  )
end

# Default stub for any other UK postcode (catch-all)
Geocoder::Lookup::Test.set_default_stub(
  [
    { 'postcode' => 'UNKNOWN',
      'quality' => 1,
      'eastings' => 400_000,
      'northings' => 400_000,
      'country' => 'England',
      'longitude' => -1.5,
      'latitude' => 53.0,
      'region' => 'Test Region',
      'admin_district' => 'Test District',
      'admin_county' => 'Test County',
      'admin_ward' => 'Test Ward',
      'codes' => {
        'admin_district' => 'E00000001',
        'admin_county' => 'E00000001',
        'admin_ward' => 'E00000001'
      } }
  ]
)
