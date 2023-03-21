# frozen_string_literal: true

require 'csv'
require 'json'

module App
  module_function

  attr_accessor :base_dir, :country_file, :region_file, :county_file, :lad_file, :ward_file, :ward_data_file

  def main
    puts 'loading'

    @country = load_lut(path_to('Documents', country_file), 0, 2)
    puts "  #{@country.count} countries"

    @region = load_lut(path_to('Documents', region_file), 0, 2)
    puts "  #{@region.count} regions"

    @county = load_lut(path_to('Documents', county_file), 0, 1)
    puts "  #{@county.count} counties"

    @lad = load_lut(path_to('Documents', lad_file), 0, 1)
    puts "  #{@lad.count} lads"

    @ward = load_lut(path_to('Documents', ward_file), 0, 1)
    puts "  #{@ward.count} wards"

    puts 'parsing'
    parse_ward_data

    puts 'constructing'
    tree = construct_neighbourhood_tree

    json_path = File.join(Dir.getwd, 'output.json')
    puts "writing payload to #{json_path}"

    File.open(json_path, 'w') do |file|
      file.puts tree.to_json
    end
  end

  def parse_ward_data
    @ward_entry = {}
    CSV.foreach(path_to('Data', ward_data_file), headers: :first_row) do |row|
      country = row[16].to_s.strip
      region  = row[17].to_s.strip
      county  = row[10].to_s.strip
      lad     = row[12].to_s.strip
      ward    = row[13].to_s.strip

      next if [country, region, county, lad, ward].any?(&:empty?)

      data = {
        county: county,
        lad: lad,
        country: country,
        region: region,
        ward: ward
      }

      @ward_entry[data[:ward]] ||= data
    end
    puts "  #{@ward_entry.count} ward entries"
  end

  def construct_neighbourhood_tree
    root = {
      id: -1,
      name: 'root',
      children: {}
    }

    @ward_entry.each do |ward_id, data|
      # puts "#{ward_id}"
      country = lookup_or_create(root, @country, data[:country])

      region = lookup_or_create(country, @region, data[:region])

      county = lookup_or_create(region, @county, data[:county])

      lad = lookup_or_create(county, @lad, data[:lad])

      # ward
      # ward_id = data[:ward]

      lad[:children][ward_id] = {
        id: ward_id,
        name: @ward[ward_id]
        # extra data here
      }
    end

    root
  end

  def lookup_or_create(input, name_lut, id)
    object = input[:children][id]
    return object if object

    new_object = {
      code: id,
      name: name_lut[id],
      children: {}
    }
    input[:children][id] = new_object

    new_object
  end

  def load_lut(filename, key_index, name_index)
    lut = {}

    CSV.foreach(filename, headers: :first_row) do |row|
      code = row[key_index]
      name = row[name_index]

      lut[code] = name
    end

    lut
  end

  def path_to(*bits)
    File.join base_dir, *bits
  end
end

# base dir of data
App.base_dir = File.join(Dir.home, 'Downloads/geo-data')

# filenames for mapping IDs to names
App.country_file = 'Country names and codes UK as at 08_12.csv'
App.region_file = 'Region names and codes EN as at 12_20 (RGN).csv'
App.county_file = 'County Electoral Division names and codes EN as at 05_21.csv'
App.lad_file = 'LA_UA names and codes UK as at 04_21.csv'
App.ward_file = 'Ward names and codes UK as at 05_21 NSPL.csv'

# the actual ward data file
App.ward_data_file = 'NSPL_MAY_2022_UK.csv'

# now just run it
App.main
