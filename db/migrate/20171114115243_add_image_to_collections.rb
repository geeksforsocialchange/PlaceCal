class AddImageToCollections < ActiveRecord::Migration[5.1]
  def change
    add_column :collections, :image, :string
  end
end
