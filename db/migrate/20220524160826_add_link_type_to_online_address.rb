class AddLinkTypeToOnlineAddress < ActiveRecord::Migration[6.1]
  def change
    add_column :online_addresses, :link_type, :string
  end
end
