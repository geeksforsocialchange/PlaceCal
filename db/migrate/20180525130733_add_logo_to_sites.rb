class AddLogoToSites < ActiveRecord::Migration[5.1]
  def change
    add_column :sites, :logo, :string
  end
end
