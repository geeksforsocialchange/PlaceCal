# frozen_string_literal: true

class CreateJoinTablePartnerTurf < ActiveRecord::Migration[5.1]
  def change
    create_join_table :partners, :turves do |t|
      t.index %i[partner_id turf_id]
      t.index %i[turf_id partner_id]
    end
  end
end
