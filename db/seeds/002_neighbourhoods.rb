# frozen_string_literal: true

require 'csv'

NEIGHBOURHOOD_HIERARCHY = [
  { prefix: 'CTRY', unit: 'country' },
  { prefix: 'RGN', unit: 'region'  },
  { prefix: 'CTY', unit: 'county'  },
  { prefix: 'LAD', unit: 'district' },
  { prefix: 'WD', unit: 'ward' }
].freeze

FILE_DATA = [
  {
    file: 'Ward_to_Local_Authority_District_to_County_to_Region_to_Country_(December_2019)_Lookup_in_United_Kingdom.csv',
    release_date: DateTime.new(2019, 12),
    lines: 8887,
    year_prefix: 19
  },
  {
    file: 'Ward_to_Local_Authority_District_to_County_to_Region_to_Country_(May_2023)_Lookup_in_United_Kingdom.csv',
    release_date: DateTime.new(2023, 5),
    lines: 8441,
    year_prefix: 23
  }
].freeze

module SeedMinimalNeighbourhoods
  def self.run
    $stdout.puts 'Neighbourhoods'

    FILE_DATA.each do |file_data|
      neighbourhood_unit_types_saved = Set[]

      CSV.foreach(Rails.root.join("lib/data/#{file_data[:file]}"), headers: true).with_index(1) do |row, _index|
        # keep loading until we have one of every neighbourhood unit
        break if neighbourhood_unit_types_saved.length > 4

        parent = nil
        NEIGHBOURHOOD_HIERARCHY.each do |metadata|
          unit_code_key = "#{metadata[:prefix]}#{file_data[:year_prefix]}CD"
          unit_name_key = "#{metadata[:prefix]}#{file_data[:year_prefix]}NM"
          unit = metadata[:unit]

          next unless row[unit_code_key]

          neighbourhood = Neighbourhood.find_or_create_by!({
                                                             name: row[unit_name_key],
                                                             unit: unit,
                                                             unit_code_key: unit_code_key,
                                                             unit_code_value: row[unit_code_key],
                                                             unit_name: row[unit_name_key]
                                                             # release_date: file_data[:release_date]
                                                           })

          neighbourhood.parent = parent
          neighbourhood.save!
          parent = neighbourhood
          neighbourhood_unit_types_saved << metadata[:prefix]
        end
      end
    end
  end
end

module SeedAllNeighbourhoods
  def self.run
    $stdout.puts 'Neighbourhoods Maximal'

    FILE_DATA.each_with_index do |file_data, file_index|
      CSV.foreach(Rails.root.join("lib/data/#{file_data[:file]}"), headers: true).with_index(1) do |row, index|
        parent = nil
        NEIGHBOURHOOD_HIERARCHY.each do |metadata|
          unit_code_key = "#{metadata[:prefix]}#{file_data[:year_prefix]}CD"
          unit_name_key = "#{metadata[:prefix]}#{file_data[:year_prefix]}NM"
          unit = metadata[:unit]

          next unless row[unit_code_key]

          neighbourhood = Neighbourhood.find_or_create_by!({
                                                             name: row[unit_name_key],
                                                             unit: unit,
                                                             unit_code_key: unit_code_key,
                                                             unit_code_value: row[unit_code_key],
                                                             unit_name: row[unit_name_key]
                                                             # release_date: file_data[:release_date]
                                                           })

          neighbourhood.parent = parent
          neighbourhood.save!
          parent = neighbourhood
        end
        $stdout.print "\r#{index}/#{file_data[:lines]} wards loaded from #{file_index + 1}/#{FILE_DATA.length} files"
      end
    end
  end
end

if ENV['SEED_ALL_NEIGHBOURHOODS']
  SeedAllNeighbourhoods.run
else
  SeedMinimalNeighbourhoods.run
end
