# frozen_string_literal: true

require_relative '../../lib/normal_island'

module SeedNeighbourhoods
  def self.run # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    $stdout.puts 'Neighbourhoods - Normal Island'

    # Country
    country = Neighbourhood.find_or_create_by!(
      unit_code_value: NormalIsland::COUNTRY[:unit_code_value]
    ) do |n|
      n.name = NormalIsland::COUNTRY[:name]
      n.name_abbr = 'ZZ'
      n.unit = NormalIsland::COUNTRY[:unit]
      n.unit_code_key = NormalIsland::COUNTRY[:unit_code_key]
      n.unit_name = NormalIsland::COUNTRY[:name]
      n.release_date = DateTime.now
    end
    $stdout.puts "  Country: #{country.name}"

    # Regions
    regions = {}
    NormalIsland::REGIONS.each do |key, data|
      regions[key] = Neighbourhood.find_or_create_by!(
        unit_code_value: data[:unit_code_value]
      ) do |n|
        n.name = data[:name]
        n.name_abbr = data[:name]
        n.unit = data[:unit]
        n.unit_code_key = data[:unit_code_key]
        n.unit_name = data[:name]
        n.release_date = DateTime.now
        n.parent = country
      end
      $stdout.puts "  Region: #{data[:name]}"
    end

    # Counties
    counties = {}
    NormalIsland::COUNTIES.each do |key, data|
      counties[key] = Neighbourhood.find_or_create_by!(
        unit_code_value: data[:unit_code_value]
      ) do |n|
        n.name = data[:name]
        n.name_abbr = data[:name]
        n.unit = data[:unit]
        n.unit_code_key = data[:unit_code_key]
        n.unit_name = data[:name]
        n.release_date = DateTime.now
        n.parent = regions[data[:parent_region]]
      end
      $stdout.puts "  County: #{data[:name]}"
    end

    # Districts
    districts = {}
    NormalIsland::DISTRICTS.each do |key, data|
      districts[key] = Neighbourhood.find_or_create_by!(
        unit_code_value: data[:unit_code_value]
      ) do |n|
        n.name = data[:name]
        n.name_abbr = data[:name]
        n.unit = data[:unit]
        n.unit_code_key = data[:unit_code_key]
        n.unit_name = data[:name]
        n.release_date = DateTime.now
        n.parent = counties[data[:parent_county]]
      end
      $stdout.puts "  District: #{data[:name]}"
    end

    # Wards
    NormalIsland::WARDS.each do |_key, data|
      Neighbourhood.find_or_create_by!(
        unit_code_value: data[:unit_code_value]
      ) do |n|
        n.name = data[:name]
        n.name_abbr = data[:name]
        n.unit = data[:unit]
        n.unit_code_key = data[:unit_code_key]
        n.unit_name = data[:name]
        n.release_date = DateTime.now
        n.parent = districts[data[:parent_district]]
      end
      $stdout.puts "  Ward: #{data[:name]}"
    end
  end
end

SeedNeighbourhoods.run
