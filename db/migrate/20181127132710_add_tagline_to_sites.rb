class AddTaglineToSites < ActiveRecord::Migration[5.1]
  def change
    add_column :sites, :tagline, :string, default: 'The Community Calendar'
  end
end
