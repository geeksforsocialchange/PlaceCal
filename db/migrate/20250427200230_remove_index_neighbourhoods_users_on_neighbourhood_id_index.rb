# frozen_string_literal: true

class RemoveIndexNeighbourhoodsUsersOnNeighbourhoodIdIndex < ActiveRecord::Migration[7.2]
  def up
    remove_index 'neighbourhoods_users', name: 'index_neighbourhoods_users_on_neighbourhood_id'
  end

  def down
    add_index 'neighbourhoods_users', :neighbourhood_id, name: 'index_neighbourhoods_users_on_neighbourhood_id'
  end
end
