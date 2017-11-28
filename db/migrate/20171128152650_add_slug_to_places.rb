class AddSlugToPlaces < ActiveRecord::Migration[5.1]
  def change
    add_column :places, :slug, :string
    add_index :places, :slug, unique: true
    Partner.find_each(&:save)
    Place.find_each(&:save)
  end
end
