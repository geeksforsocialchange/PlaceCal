class DropSitesTurfsTable < ActiveRecord::Migration[5.1]
  def change
  	drop_table :sites_turfs 
  end
end
