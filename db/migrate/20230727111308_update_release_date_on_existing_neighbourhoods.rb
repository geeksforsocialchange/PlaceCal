# frozen_string_literal: true

class UpdateReleaseDateOnExistingNeighbourhoods < ActiveRecord::Migration[6.1]
  def change
    neighbourhoods = Neighbourhood.where('unit_code_key like ?', '%19%')
    neighbourhoods.each do |neighbourhood|
      neighbourhood.release_date = DateTime.new(2019, 12)
      neighbourhood.save!
    end
  end
end
