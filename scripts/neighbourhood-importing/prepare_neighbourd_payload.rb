# frozen_string_literal: true

require 'csv'
require 'json'

module App
  extend self

  attr_accessor :base_dir, :country_file, :region_file, :county_file, :lad_file, :ward_file, :ward_data_file, :ward_field_map

  def main
    puts 'loading'

    @country, @country_key_name = load_lut(path_to('Documents', country_file), 0, 2)
    puts "  #{@country.count} countries / #{@country_key_name}"

    @region, @region_key_name = load_lut(path_to('Documents', region_file), 0, 2)
    puts "  #{@region.count} regions / #{@region_key_name}"

    @county, @county_key_name = load_lut(path_to('Documents', county_file), 0, 1)
    puts "  #{@county.count} counties / #{@county_key_name}"

    @lad, @lad_key_name = load_lut(path_to('Documents', lad_file), 0, 1)
    puts "  #{@lad.count} lads / #{@lad_key_name}"

    @ward, @ward_key_name = load_lut(path_to('Documents', ward_file), 0, 1)
    puts "  #{@ward.count} wards / #{@ward_key_name}"

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
    
    country_field  = ward_field_map[:country]
    region_field   = ward_field_map[:region]
    county_field   = ward_field_map[:county]
    district_field = ward_field_map[:district]
    ward_field     = ward_field_map[:ward]
    
    CSV.foreach(path_to('Data', ward_data_file), headers: :first_row) do |row|
      country = row[ country_field].to_s.strip
      region  = row[  region_field].to_s.strip
      county  = row[  county_field].to_s.strip
      lad     = row[district_field].to_s.strip
      ward    = row[    ward_field].to_s.strip

      # next if [country, region, county, lad, ward].any?(&:empty?)

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
      country = lookup_or_create(root, @country, 'country', @country_key_name, data[:country])
      next if country.nil?
      
      region = lookup_or_create(country, @region, 'region', @region_key_name, data[:region])
      next if region.nil?

      county = lookup_or_create(region, @county, 'county', @county_key_name, data[:county])
      next if county.nil?

      lad = lookup_or_create(county, @lad, 'district', @lad_key_name, data[:lad])
      next if lad.nil?

      # ward
      # ward_id = data[:ward]

      lad[:children][ward_id] = {
        code: ward_id,
        type: 'ward',
        name: @ward[ward_id],
        key_name: @ward_key_name
        # extra data here
      }
      # puts @ward_key_name
    end

    root
  end

  def lookup_or_create(input, name_lut, type_name, key_name, id)
    return if id.to_s.strip.empty?
    
    object = input[:children][id]
    return object if object

    new_object = {
      code: id,
      type: type_name,
      name: name_lut[id],
      key_name: key_name,
      children: {}
    }
    input[:children][id] = new_object
    # puts key_name

    new_object
  end

  def load_lut(filename, key_index, name_index)
    lut = {}
    key_name = nil

    CSV.foreach(filename, headers: :first_row) do |row|
      key_name ||= row.headers[name_index]
                     
      code = row[key_index]
      name = row[name_index]

      lut[code] = name
    end

    [ lut, key_name ]
  end

  def path_to(*bits)
    File.join base_dir, *bits
  end
end



###############
#
# May 2019
#
###############

=begin
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
App.ward_field_map = {
  country: 'ctry',
  region: 'rgn',
  county: 'cty',
  district: 'laua',
  ward: 'ward'
}
=end

###############
#
# Nov 2022
#
###############

# base dir of data
App.base_dir = '/mnt/internal-hd/home/ivan/tmp/geo-data/nov-2022'

# filenames for mapping IDs to names
App.country_file = 'Country names and codes UK as at 08_12.csv'
App.region_file = 'Region names and codes EN as at 12_20 (RGN).csv'
App.county_file = 'County names and codes UK as at 04_21.csv'
App.lad_file = 'LA_UA names and codes UK as at 04_21.csv'
App.ward_file = 'Ward names and codes UK as at 12_22_NSPD.csv'

# the actual ward data file
App.ward_data_file = 'ONSPD_NOV_2022_UK.csv'

App.ward_field_map = {
  country: 'ctry',
  region: 'rgn',
  county: 'oscty',
  district: 'oslaua',
  ward: 'osward'
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# now just run it
App.main
