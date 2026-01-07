# frozen_string_literal: true

class ChangeUsersRoleNullConstraint < ActiveRecord::Migration[7.2]
  def change
    # Step 1: Clean up existing NULLs (only on migrate up, not down)
    up_only do
      execute <<-SQL.squish
          DELETE FROM users WHERE role IS NULL;
      SQL
    end

    # Step 2: Now it's safe to add NOT NULL
    change_column_null :users, :role, false
  end
end
