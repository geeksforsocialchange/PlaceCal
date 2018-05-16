# frozen_string_literal: true

class CreateJoinTableTurfUser < ActiveRecord::Migration[5.1]
  def change
    create_join_table :turves, :users do |t|
      t.index %i[turf_id user_id]
      t.index %i[user_id turf_id]
    end
  end
end
