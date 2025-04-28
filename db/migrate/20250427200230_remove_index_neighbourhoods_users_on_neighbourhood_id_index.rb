# frozen_string_literal: true

class RemoveIndexNeighbourhoodsUsersOnNeighbourhoodIdIndex < ActiveRecord::Migration[7.2]
  def change
    reversible do |dir|
      dir.up do
        remove_index 'neighbourhoods_users', name: 'index_neighbourhoods_users_on_neighbourhood_id'
      end

      dir.down do
        add_index 'neighbourhoods_users', :neighbourhood_id, name: 'index_neighbourhoods_users_on_neighbourhood_id'
      end
    end
  end
end
