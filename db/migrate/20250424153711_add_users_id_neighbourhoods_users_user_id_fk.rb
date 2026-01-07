# frozen_string_literal: true

class AddUsersIdNeighbourhoodsUsersUserIdFk < ActiveRecord::Migration[7.2]
  def change
    add_foreign_key :neighbourhoods_users, :users, column: :user_id, primary_key: :id
  end
end
