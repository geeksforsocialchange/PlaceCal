class CreateJoinTablePartnerTurf < ActiveRecord::Migration[5.1]
  def change
    create_join_table :partners, :turves do |t|
      t.index [:partner_id, :turf_id]
      t.index [:turf_id, :partner_id]
    end
  end
end
