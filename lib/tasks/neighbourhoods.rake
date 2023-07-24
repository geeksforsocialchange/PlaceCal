# frozen_string_literal: true

neighbourhood_hierarchy = [
  { prefix: 'CTRY', unit: 'country' },
  { prefix: 'RGN', unit: 'region'  },
  { prefix: 'CTY', unit: 'county'  },
  { prefix: 'LAD', unit: 'district' },
  { prefix: 'WD', unit: 'ward' }
].freeze

files = [
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

namespace :neighbourhoods do
  desc 'find or create all available neighbourhoods'
  task import: :environment do
    # store a list of everything we already have so that we only have to find_or_create new neighbourhoods
    all_stored_neighbourhoods = Neighbourhood.pluck :unit_code_value, :release_date

    files.each_with_index do |file_data, file_index|
      CSV.foreach(Rails.root.join("lib/data/#{file_data[:file]}"), headers: true).with_index(1) do |row, index|
        parent_data = []
        neighbourhood_hierarchy.each do |metadata|
          unit_code_key = "#{metadata[:prefix]}#{file_data[:year_prefix]}CD"
          unit_name_key = "#{metadata[:prefix]}#{file_data[:year_prefix]}NM"
          unit = metadata[:unit]

          unless all_stored_neighbourhoods.include?([row[unit_code_key], file_data[:release_date]])
            neighbourhood = Neighbourhood.create!(
              {
                name: row[unit_name_key],
                unit: unit,
                unit_code_key: unit_code_key,
                unit_code_value: row[unit_code_key],
                unit_name: row[unit_name_key],
                release_date: file_data[:release_date]
              }
            )

            if parent_data.length > 1
              neighbourhood.parent = Neighbourhood.find_by(
                {
                  unit_code_key: parent_data[1],
                  unit_code_value: parent_data[0]
                }
              )
            end
            neighbourhood.save!
          end
          parent_data = [row[unit_code_key], unit_code_key]
        end
        $stdout.print "\r#{index}/#{file_data[:lines]} wards loaded from #{file_index + 1}/#{files.length} files"
      end
    end
  end
end
