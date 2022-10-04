# frozen_string_literal: true

class FixBrokenDatamodel < ActiveRecord::Migration[6.1]
  # This code is hecking UGLY
  def create_unit(json_unit, parent_neighbourhood, parent_unit)
    structure = { name: json_unit['properties']['name'],
                  unit: json_unit['properties']['unit'],
                  unit_code_key: json_unit['properties']['unit_code_key'],
                  unit_code_value: json_unit['properties']['code'],
                  unit_name: json_unit['properties']['name'] }

    # We do not want to recreate wards that already exist, but we don't want to waste our
    # cycles finding unit levels that don't exist
    # Ergo, if the parent unit is a district that means that we are at ward level,
    #

    u = if parent_unit == 'district'
          Neighbourhood.find_or_create_by!(structure)
        else
          u = Neighbourhood.create!(structure)
        end

    u.save! # Ancestry methods not available until the neighbourhood unit has been saved

    u.parent = parent_neighbourhood if parent_neighbourhood

    u.save! # Now we can save the ancestry of the neighbourhood unit

    # If it's not a ward, then we need to create it's children
    return if u.unit == 'ward'

    json_unit['children'].each_value do |subunit|
      create_unit(subunit, u, u.unit)
    end
  end

  def up
    errors = []
    begin
      # Remove all wards that have ancestry data or are a country (countries lack ancestry data)
      Neighbourhood.find_each do |ward|
        next unless !ward.ancestry.nil? || ward.unit == 'country'

        ward.destroy!
      end

      # Out with the old, and now? In with the new
      # Loads the new geodata
      json_data = File.open('db/location-lookup-data-v3.json', 'r') do |f|
        JSON.parse f.read
      end

      json_data.each_value do |country|
        create_unit(country, nil, nil)
      end
    rescue StandardError => e
      errors << { error: e.message,
                  trace: e.backtrace_locations }
    end

    # Recover from Errors
    return unless errors.any?

    File.write('20220105161548_fix_broken_datamodel.errors', errors)
  end
end
