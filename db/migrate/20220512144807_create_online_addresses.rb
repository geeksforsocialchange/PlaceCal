class CreateOnlineAddresses < ActiveRecord::Migration[6.1]
  def change
    create_table :online_addresses do |t|
      t.string :url
      t.timestamps
    end
    add_reference :events, :online_address, foreign_key: true
  end
end
