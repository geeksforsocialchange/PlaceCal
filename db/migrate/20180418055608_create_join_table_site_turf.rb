# frozen_string_literal: true

class CreateJoinTableSiteTurf < ActiveRecord::Migration[5.1]
  def change
    create_join_table :sites, :turfs do |t|
      t.index %i[site_id turf_id]
      t.index %i[turf_id site_id]
    end
  end
end
