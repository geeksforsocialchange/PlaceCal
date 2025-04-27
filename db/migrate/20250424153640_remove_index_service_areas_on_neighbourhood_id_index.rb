# frozen_string_literal: true

class RemoveIndexServiceAreasOnNeighbourhoodIdIndex < ActiveRecord::Migration[7.2]
  def change
    # remove_index 'service_areas', name: 'index_service_areas_on_neighbourhood_id'
    remove_index :service_areas, :neighbourhoods
  end
end
