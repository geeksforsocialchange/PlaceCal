# frozen_string_literal: true

class AddCounterCachesToSites < ActiveRecord::Migration[7.2]
  def change
    add_column :sites, :partners_count, :integer, default: 0, null: false
    add_column :sites, :events_count, :integer, default: 0, null: false

    add_index :sites, :partners_count
    add_index :sites, :events_count
  end
end
