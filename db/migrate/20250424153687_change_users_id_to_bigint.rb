# frozen_string_literal: true

class ChangeUsersIdToBigint < ActiveRecord::Migration[7.2]
  def up
    change_column :users, :id, :bigint
  end

  def down
    change_column :users, :id, :integer
  end
end
