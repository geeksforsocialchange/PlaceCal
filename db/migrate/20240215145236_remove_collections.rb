# frozen_string_literal: true

class RemoveCollections < ActiveRecord::Migration[7.1]
  def self.up
    drop_table :collections
    drop_table :collections_events
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
