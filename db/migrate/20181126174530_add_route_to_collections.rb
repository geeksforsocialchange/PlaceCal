class AddRouteToCollections < ActiveRecord::Migration[5.1]
  def change
    add_column :collections, :route, :string
  end
end
