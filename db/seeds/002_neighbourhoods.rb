# frozen_string_literal: true

module SeedNeighbourhoods
  def self.run
    $stdout.puts 'Neighbourhoods'

    country = Neighbourhood.create!(
      name: 'England',
      name_abbr: '',
      unit: 'country',
      unit_code_key: 'CTRY19CD',
      unit_code_value: 'E92000001',
      unit_name: 'England',
      release_date: DateTime.now
    )

    region = Neighbourhood.create!(
      name: 'North West',
      name_abbr: 'North West',
      unit: 'region',
      unit_code_key: 'RGN19CD',
      unit_code_value: 'E12000002',
      unit_name: 'North West',
      release_date: DateTime.now,

      parent: country
    )

    county = Neighbourhood.create!(
      name: 'Greater Manchester',
      name_abbr: 'Greater Manchester',
      unit: 'county',
      unit_code_key: 'CTY19CD',
      unit_code_value: 'E11000001',
      unit_name: 'Greater Manchester',
      release_date: DateTime.now,

      parent: region
    )

    district = Neighbourhood.create!(
      name: 'Manchester',
      name_abbr: 'Manchester',
      unit: 'district',
      unit_code_key: 'LAD19CD',
      unit_code_value: 'E08000003',
      unit_name: 'Manchester',
      release_date: DateTime.now,

      parent: county
    )

    ward = Neighbourhood.create!(
      name: 'Hulme Longname',
      name_abbr: 'Hulme',
      unit: 'ward',
      unit_code_key: 'WD19CD',
      unit_code_value: 'E05011368',
      unit_name: 'Hulme',
      release_date: DateTime.now,

      parent: district
    )
  end
end

SeedNeighbourhoods.run
