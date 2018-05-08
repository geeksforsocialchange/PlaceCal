class CreateJoinTablePlaceTurf < ActiveRecord::Migration[5.1]
  def change
    create_join_table :places, :turfs do |t|
      t.index [:place_id, :turf_id]
      t.index [:turf_id, :place_id]
    end
  end
end
