class CreateJoinTableSiteTurf < ActiveRecord::Migration[5.1]
  def change
    create_join_table :sites, :turfs do |t|
      t.index [:site_id, :turf_id]
      t.index [:turf_id, :site_id]
    end
  end
end
