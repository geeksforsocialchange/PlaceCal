class AddThemeToSites < ActiveRecord::Migration[6.0]
  def change
    add_column :sites, :theme, :string
  end
end
