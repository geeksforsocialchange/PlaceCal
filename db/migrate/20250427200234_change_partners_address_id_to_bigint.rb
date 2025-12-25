# frozen_string_literal: true

class ChangePartnersAddressIdToBigint < ActiveRecord::Migration[7.2]
  def up
    change_column :partners, :address_id, :bigint
  end

  def down
    change_column :partners, :address_id, :integer
  end
end
