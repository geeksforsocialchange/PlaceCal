# frozen_string_literal: true

class DropRetiredTables < ActiveRecord::Migration[8.1]
  def up
    drop_table :organisation_relationships
    drop_table :collections_events
    drop_table :collections
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
