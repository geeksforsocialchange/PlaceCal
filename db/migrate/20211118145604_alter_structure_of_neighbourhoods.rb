# frozen_string_literal: true

class AlterStructureOfNeighbourhoods < ActiveRecord::Migration[6.0]
  def up
    errors = []
    Neighbourhood.find_each do |ward|
      next if ward.unit != 'ward'

      puts "Processing ward #{ward.id}, #{ward.name}"

      # Nice variables
      # Often we do not actually have name / code data for the county or region nodes.
      # The values .ward, .district, .county, .region are all more accurate than that code data
      district_name = ward.district
      county_name = ward.county
      region_name = ward.region

      # Fill ward with default values
      ward.unit_code_value = ward.WD19CD
      ward.unit_name = ward.name

      # Find/Create district and county neighbourhoods
      district_node = Neighbourhood.find_or_create_by!(
        { name: district_name,
          unit: 'district',
          unit_code_key: 'LAD19CD',
          unit_code_value: ward.LAD19CD,
          unit_name: district_name }
      )
      county_node = Neighbourhood.find_or_create_by!(
        { name: county_name,
          unit: 'county',
          unit_code_key: 'CTY19CD',
          unit_code_value: ward.CTY19CD,
          unit_name: county_name }
      )
      region_node = Neighbourhood.find_or_create_by!(
        { name: region_name,
          unit: 'region',
          unit_code_key: 'RGN19CD',
          unit_code_value: ward.RGN19CD,
          unit_name: region_name }
      )

      # Make the ward a child of the district
      ward.parent = district_node

      # Make the district a child of the county, if it isn't already
      district_node.parent = county_node unless
        county_node.children.include? district_node

      county_node.parent = region_node unless
        region_node.children.include? county_node

      # Save save save!!!
      ward.save!
      district_node.save!
      county_node.save!
      region_node.save!
    rescue StandardError => e
      errors << { error: e.message,
                  trace: e.backtrace_locations,
                  id: ward.id,
                  name: ward.name }
      next
    end

    return unless errors.any?

    File.write('20211118145604_alter_structure_of_neighbourhoods.errors.txt', errors)
  end

  def down
    puts 'WARNING: Downgrade path has NOT been verified and should be manually verified first.'
    errors = []
    Neighbourhood.find_each do |ward|
      next if ward.unit == 'ward'

      puts "Destroying non-ward item of type #{ward.unit} with name #{ward.name}"
      ward.destroy!
    rescue StandardError => e
      errors << { error: e.message,
                  trace: e.backtrace_locations,
                  id: ward.id,
                  name: ward.name }
    end

    return unless errors.any?

    File.write('20211118145604_alter_structure_of_neighbourhoods.errors.txt', errors)
  end
end
