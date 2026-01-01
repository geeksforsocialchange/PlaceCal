# frozen_string_literal: true

require_relative '../../lib/normal_island'

module SeedNeighbourhoods
  def self.run
    $stdout.puts 'Neighbourhoods - Normal Island'

    # Country
    country = Neighbourhood.create!(
      name: NormalIsland::COUNTRY[:name],
      name_abbr: 'ZZ',
      unit: NormalIsland::COUNTRY[:unit],
      unit_code_key: NormalIsland::COUNTRY[:unit_code_key],
      unit_code_value: NormalIsland::COUNTRY[:unit_code_value],
      unit_name: NormalIsland::COUNTRY[:name],
      release_date: DateTime.now
    )
    $stdout.puts "  Created country: #{country.name}"

    # Regions
    regions = {}
    NormalIsland::REGIONS.each do |key, data|
      regions[key] = Neighbourhood.create!(
        name: data[:name],
        name_abbr: data[:name],
        unit: data[:unit],
        unit_code_key: data[:unit_code_key],
        unit_code_value: data[:unit_code_value],
        unit_name: data[:name],
        release_date: DateTime.now,
        parent: country
      )
      $stdout.puts "  Created region: #{data[:name]}"
    end

    # Counties
    counties = {}
    NormalIsland::COUNTIES.each do |key, data|
      counties[key] = Neighbourhood.create!(
        name: data[:name],
        name_abbr: data[:name],
        unit: data[:unit],
        unit_code_key: data[:unit_code_key],
        unit_code_value: data[:unit_code_value],
        unit_name: data[:name],
        release_date: DateTime.now,
        parent: regions[data[:parent_region]]
      )
      $stdout.puts "  Created county: #{data[:name]}"
    end

    # Districts
    districts = {}
    NormalIsland::DISTRICTS.each do |key, data|
      districts[key] = Neighbourhood.create!(
        name: data[:name],
        name_abbr: data[:name],
        unit: data[:unit],
        unit_code_key: data[:unit_code_key],
        unit_code_value: data[:unit_code_value],
        unit_name: data[:name],
        release_date: DateTime.now,
        parent: counties[data[:parent_county]]
      )
      $stdout.puts "  Created district: #{data[:name]}"
    end

    # Wards
    NormalIsland::WARDS.each do |_key, data|
      Neighbourhood.create!(
        name: data[:name],
        name_abbr: data[:name],
        unit: data[:unit],
        unit_code_key: data[:unit_code_key],
        unit_code_value: data[:unit_code_value],
        unit_name: data[:name],
        release_date: DateTime.now,
        parent: districts[data[:parent_district]]
      )
      $stdout.puts "  Created ward: #{data[:name]}"
    end
  end
end

SeedNeighbourhoods.run
