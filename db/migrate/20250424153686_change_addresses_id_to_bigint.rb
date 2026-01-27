# frozen_string_literal: true

class ChangeAddressesIdToBigint < ActiveRecord::Migration[7.2]
  def up
    change_column :addresses, :id, :bigint
  end

  def down
    change_column :addresses, :id, :integer
  end
end
