# frozen_string_literal: true

class ChangeUsersRoleNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :users, :role, false
  end
end
