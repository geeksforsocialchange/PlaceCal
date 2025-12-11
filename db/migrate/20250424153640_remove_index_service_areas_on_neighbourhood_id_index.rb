# frozen_string_literal: true

class RemoveIndexServiceAreasOnNeighbourhoodIdIndex < ActiveRecord::Migration[7.2]
  def up
    remove_index 'service_areas', name: 'index_service_areas_on_neighbourhood_id'
  end

  def down
    add_index 'service_areas', :neighbourhood_id, name: 'index_service_areas_on_neighbourhood_id'
  end
end
