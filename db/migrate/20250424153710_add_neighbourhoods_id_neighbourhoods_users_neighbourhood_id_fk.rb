# frozen_string_literal: true

class AddNeighbourhoodsIdNeighbourhoodsUsersNeighbourhoodIdFk < ActiveRecord::Migration[7.2]
  def change
    add_foreign_key :neighbourhoods_users, :neighbourhoods, column: :neighbourhood_id, primary_key: :id
  end
end
