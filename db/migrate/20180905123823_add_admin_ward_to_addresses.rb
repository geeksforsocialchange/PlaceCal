# frozen_string_literal: true

class AddAdminWardToAddresses < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses, :admin_ward, :string
  end
end
