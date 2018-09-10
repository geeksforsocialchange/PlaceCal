class RemoveAdminWardFromAddresses < ActiveRecord::Migration[5.1]
  def change
    remove_column :addresses, :admin_ward, :string
  end
end
