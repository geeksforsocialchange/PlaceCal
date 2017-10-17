class AddContactToPlaces < ActiveRecord::Migration[5.1]
  def change
    add_column :places, :email, :string
    add_column :places, :url, :string
  end
end
