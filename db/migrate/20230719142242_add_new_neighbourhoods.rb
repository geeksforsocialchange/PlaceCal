# frozen_string_literal: true

require 'csv'

class AddNewNeighbourhoods < ActiveRecord::Migration[6.1]
  NEIGHBOURHOOD_HIERARCHY = [
    { prefix: 'CTRY', unit: 'country' },
    { prefix: 'RGN', unit: 'region'  },
    { prefix: 'CTY', unit: 'county'  },
    { prefix: 'LAD', unit: 'district' },
    { prefix: 'WD', unit: 'ward' }
  ].freeze

  FILE_DATA = {
    file: 'Ward_to_Local_Authority_District_to_County_to_Region_to_Country_(May_2023)_Lookup_in_United_Kingdom.csv',
    release_date: DateTime.new(2023, 5)
  }.freeze

  def change
    errors = []
    CSV.foreach(Rails.root.join("lib/data/#{FILE_DATA[:file]}"), headers: true) do |row|
      parent = nil

      NEIGHBOURHOOD_HIERARCHY.each_with_index do |metadata, _index|
        unit_code_key = "#{metadata[:prefix]}23CD"
        unit_name_key = "#{metadata[:prefix]}23NM"
        unit = metadata[:unit]

        begin
          if row[unit_code_key]
            neighbourhood = Neighbourhood.find_or_create_by!({
                                                               name: row[unit_name_key],
                                                               unit: unit,
                                                               unit_code_key: unit_code_key,
                                                               unit_code_value: row[unit_code_key],
                                                               unit_name: row[unit_name_key],
                                                               release_date: FILE_DATA[:release_date]
                                                             })

            neighbourhood.parent = parent
            neighbourhood.save!
            parent = neighbourhood
          end
        rescue StandardError => e
          errors << { error: e.message,
                      trace: e.backtrace_locations,
                      id: ward.id,
                      name: ward.name }
        end
      end
    end

    return unless errors.any?

    File.write('20230719142242_add_new_neighbourhoods.txt', errors)
  end
end
