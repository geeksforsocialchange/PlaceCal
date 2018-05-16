# frozen_string_literal: true

class CreateJoinTableCollectionEvent < ActiveRecord::Migration[5.1]
  def change
    create_join_table :collections, :events do |t|
      t.index %i[collection_id event_id]
      t.index %i[event_id collection_id]
    end
  end
end
