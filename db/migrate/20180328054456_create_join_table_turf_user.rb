class CreateJoinTableTurfUser < ActiveRecord::Migration[5.1]
  def change
    create_join_table :turves, :users do |t|
      t.index [:turf_id, :user_id]
      t.index [:user_id, :turf_id]
    end
  end
end
