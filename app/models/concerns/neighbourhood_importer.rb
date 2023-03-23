# frozen_string_literal: true

class NeighbourhoodImporter
  attr_reader :payload_path
  TYPES = %w[country region county district ward]
  
  def initialize(path)
    @payload_path = path
    raise "No input file given" unless path.present?
  end

  def run
    puts "Importing from #{payload_path}"
    # postcodes = Address.pluck(:postcode).uniq

    puts '  clearing neighbourhoods'
    Neighbourhood.destroy_all

    puts '  parsing JSON'
    data = JSON.parse(File.open(payload_path).read)

    # puts data.length
    Neighbourhood.transaction do
      puts '  inserting neighbourhoods'
      process_entry nil, 0, data
    end

    puts 'done.'
  end

  def process_entry(parent, depth, data)
    # puts data.keys.join(', ')
    
    neighbourhood = Neighbourhood.create! do |nh|
      if parent.present?
        nh.parent = parent
        nh.parent_name = parent.name
      end

      nh.name = data['name']
      nh.unit = data['type']
      nh.unit_name = data['name']
      nh.unit_code_value = data['code']
      nh.unit_code_key = data['key_name']
    end

    if data.has_key?('children')
      data['children'].each do |id, child_data|
        process_entry neighbourhood, depth + 1, child_data
      end
    end
  end
end

#    * t.string "name"
#    x t.string "name_abbr"
#    x t.string "ancestry"
#    * t.string "unit", default: "ward"
#    * t.string "unit_code_key", default: "WD19CD"
#    * t.string "unit_code_value"
#    * t.string "unit_name"
#    * t.string "parent_name"
