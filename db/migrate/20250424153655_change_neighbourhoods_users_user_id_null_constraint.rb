# frozen_string_literal: true

class ChangeNeighbourhoodsUsersUserIdNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :neighbourhoods_users, :user_id, false
  end
end
