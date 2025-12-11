# frozen_string_literal: true

class ChangeNeighbourhoodsUsersNeighbourhoodIdNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :neighbourhoods_users, :neighbourhood_id, false
  end
end
