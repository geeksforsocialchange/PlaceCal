class CreateSitesTurfs < ActiveRecord::Migration[5.1]
  def change
    create_table :sites_turfs do |t|
      t.integer :turf_id
      t.integer :site_id
      t.string :relation_type

      t.timestamps
    end
  end
end
