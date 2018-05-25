class AddFooterLogoToSites < ActiveRecord::Migration[5.1]
  def change
    add_column :sites, :footer_logo, :string
  end
end
