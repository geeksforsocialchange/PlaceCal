# frozen_string_literal: true

class AddNeighbourhoodsUsersNeighbourhoodIdUserIdIndex < ActiveRecord::Migration[7.2]
  def change
    add_index :neighbourhoods_users, %w[neighbourhood_id user_id], name: :index_neighbourhoods_users_neighbourhood_id_user_id, unique: true
  end
end
