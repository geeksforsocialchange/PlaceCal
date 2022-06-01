class AddIsStreamToOnlineAddress < ActiveRecord::Migration[6.1]
  def change
    add_column :online_addresses, :is_stream, :boolean
  end
end
