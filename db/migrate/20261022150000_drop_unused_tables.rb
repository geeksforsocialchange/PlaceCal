# frozen_string_literal: true

class DropUnusedTables < ActiveRecord::Migration[8.1]
  def up
    drop_table :friendly_id_slugs
    drop_table :seed_migration_data_migrations
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
