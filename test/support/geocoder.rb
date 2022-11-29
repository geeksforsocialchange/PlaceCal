# frozen_string_literal: true

Geocoder.configure(lookup: :test, ip_lookup: :test)

# Geocoder returns hash with string keys, not symbols
Geocoder::Lookup::Test.add_stub(
  'M15 5DD', [
    { 'postcode' => 'M15 5DD',
      'quality' => 1,
      'eastings' => 383_417,
      'northings' => 395_997,
      'country' => 'England',
      'nhs_ha' => 'North West',
      'longitude' => -2.251226,
      'latitude' => 53.460456,
      'european_electoral_region' => 'North West',
      'primary_care_trust' => 'Manchester Teaching',
      'region' => 'North West',
      'lsoa' => 'Manchester 019A',
      'msoa' => 'Manchester 019',
      'incode' => '5DD',
      'outcode' => 'M15',
      'parliamentary_constituency' => 'Manchester Central',
      'admin_district' => 'Manchester',
      'parish' => 'Manchester, unparished area',
      'admin_county' => nil,
      'admin_ward' => 'Hulme',
      'ced' => nil,
      'ccg' => 'NHS Manchester',
      'nuts' => 'Manchester',
      'codes' => {
        'admin_district' => 'E08000003',
        'admin_county' => 'E99999999',
        'admin_ward' => 'E05011368',
        'parish' => 'E43000157',
        'parliamentary_constituency' => 'E14000807',
        'ccg' => 'E38000217',
        'ccg_id' => '14L',
        'ced' => 'E99999999',
        'nuts' => 'UKD33'
      } }
  ]
)

Geocoder::Lookup::Test.add_stub(
  'OL6 8BH', [
    { 'postcode' => 'OL6 8BH',
      'quality' => 1,
      'eastings' => 394_989,
      'northings' => 401_394,
      'country' => 'England',
      'nhs_ha' => 'North West',
      'longitude' => -2.077027,
      'latitude' => 53.509207,
      'european_electoral_region' => 'North West',
      'primary_care_trust' => 'Tameside and Glossop',
      'region' => 'North West',
      'lsoa' => 'Tameside 002A',
      'msoa' => 'Tameside 002',
      'incode' => '8BH',
      'outcode' => 'OL6',
      'parliamentary_constituency' => 'Ashton-under-Lyne',
      'admin_district' => 'Tameside',
      'parish' => 'Tameside, unparished area',
      'admin_county' => nil,
      'admin_ward' => 'Ashton Hurst',
      'ced' => nil,
      'ccg' => 'NHS Tameside and Glossop',
      'nuts' => 'Greater Manchester South East',
      'codes' => {
        'admin_district' => 'E08000008',
        'admin_county' => 'E99999999',
        'admin_ward' => 'E05000800',
        'parish' => 'E43000162',
        'parliamentary_constituency' => 'E14000537',
        'ccg' => 'E38000182',
        'ccg_id' => '01Y',
        'ced' => 'E99999999',
        'nuts' => 'UKD35'
      } }
  ]
)

# this compliments the neighbourhood fixture in test/fixtures/neighbourhood.yml
Geocoder::Lookup::Test.add_stub(
  'M16 7BA', [
    {
      'postcode' => 'M16 7BA',
      'quality' => 1,
      'eastings' => 383_321,
      'northings' => 395_843,
      'country' => 'England',
      'nhs_ha' => 'North West',
      'longitude' => -2.252664,
      'latitude' => 53.459069,
      'european_electoral_region' => 'North West',
      'primary_care_trust' => 'Manchester Teaching',
      'region' => 'North West',
      'lsoa' => 'Manchester 024B',
      'msoa' => 'Manchester 024',
      'incode' => '7BA',
      'outcode' => 'M16',
      'parliamentary_constituency' => 'Manchester Central',
      'admin_district' => 'Manchester',
      'parish' => 'Manchester, unparished area',
      'admin_county' => nil,
      'admin_ward' => 'Moss Side',
      'ced' => nil,
      'ccg' => 'NHS Manchester',
      'nuts' => 'Manchester',
      'codes' => {
        'admin_district' => 'E08000003',
        'admin_county' => 'E99999999',
        'admin_ward' => 'E05011372',
        'parish' => 'E43000157',
        'parliamentary_constituency' => 'E14000807',
        'ccg' => 'E38000217',
        'ccg_id' => '14L',
        'ced' => 'E99999999',
        'nuts' => 'TLD33',
        'lsoa' => 'E01005243',
        'msoa' => 'E02001068',
        'lau2' => 'E08000003'
      }
    }
  ]
)

Geocoder::Lookup::Test.add_stub(
  'W1J 7NF', [
    { 'postcode' => 'W1J 7NF',
      'quality' => 1,
      'eastings' => 528_846,
      'northings' => 180_187,
      'country' => 'England',
      'nhs_ha' => 'London',
      'longitude' => -0.144903,
      'latitude' => 51.505935,
      'european_electoral_region' => 'London',
      'primary_care_trust' => 'Westminster',
      'region' => 'London',
      'lsoa' => 'Westminster 018D',
      'msoa' => 'Westminster 018',
      'incode' => '7NF',
      'outcode' => 'W1J',
      'parliamentary_constituency' => 'Cities of London and Westminster',
      'admin_district' => 'Westminster',
      'parish' => 'Westminster, unparished area',
      'admin_county' => nil,
      'admin_ward' => 'West End',
      'ced' => nil,
      'ccg' => 'NHS North West London',
      'nuts' => 'Westminster',
      'codes' => {
        'admin_district' => 'E09000033',
        'admin_county' => 'E99999999',
        'admin_ward' => 'E05013808',
        'parish' => 'E43000236',
        'parliamentary_constituency' => 'E14000639',
        'ccg' => 'E38000256',
        'ccg_id' => 'W2U3Z',
        'ced' => 'E99999999',
        'nuts' => 'TLI32',
        'lsoa' => 'E01004761',
        'msoa' => 'E02000977',
        'lau2' => 'E09000033'
      } }
  ]
)

Geocoder::Lookup::Test.add_stub(
  'TQ3 2NJ', [
    { 'postcode' => 'TQ3 2NJ',
      'quality' => 1,
      'eastings' => 289_380,
      'northings' => 61_302,
      'country' => 'England',
      'nhs_ha' => 'South West',
      'longitude' => -3.559171,
      'latitude' => 50.441107,
      'european_electoral_region' => 'South West',
      'primary_care_trust' => 'Torbay',
      'region' => 'South West',
      'lsoa' => 'Torbay 014A',
      'msoa' => 'Torbay 014',
      'incode' => '2NJ',
      'outcode' => 'TQ3',
      'parliamentary_constituency' => 'Torbay',
      'admin_district' => 'Torbay',
      'parish' => 'Torbay, unparished area',
      'admin_county' => nil,
      'admin_ward' => 'Preston',
      'ced' => nil,
      'ccg' => 'NHS Devon',
      'nuts' => 'Torbay',
      'codes' => {
        'admin_district' => 'E06000027',
        'admin_county' => 'E99999999',
        'admin_ward' => 'E05012263',
        'parish' => 'E43000022',
        'parliamentary_constituency' => 'E14000999',
        'ccg' => 'E38000230',
        'ccg_id' => '15N',
        'ced' => 'E99999999',
        'nuts' => 'TLK42',
        'lsoa' => 'E01015229',
        'msoa' => 'E02003167',
        'lau2' => 'E06000027'
      } }

  ]
)
