# frozen_string_literal: true

class RemoveIndexServiceAreasOnNeighbourhoodIdIndex < ActiveRecord::Migration[7.2]
  def change
    reversible do |dir|
      dir.up   { remove_index 'service_areas', name: 'index_service_areas_on_neighbourhood_id' }
      dir.down { add_index 'service_areas', :site_id, name: 'index_service_areas_on_neighbourhood_id' }
    end
  end
end
