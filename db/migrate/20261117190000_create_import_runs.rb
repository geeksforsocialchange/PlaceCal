# frozen_string_literal: true

class CreateImportRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :import_runs do |t|
      t.references :calendar, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.datetime :started_at, null: false
      t.datetime :finished_at
      t.string :outcome
      t.string :importer
      t.text :error
      t.jsonb :notices, null: false, default: []
      t.integer :events_added, null: false, default: 0
      t.integer :events_changed, null: false, default: 0
      t.integer :events_removed, null: false, default: 0
      t.integer :events_skipped, null: false, default: 0
    end
    add_index :import_runs, %i[calendar_id started_at]

    create_table :import_run_events do |t|
      t.references :import_run, null: false, foreign_key: { on_delete: :cascade }
      t.string :uid, null: false
      t.string :title
      t.text :location
      t.string :location_result, null: false
      t.text :reason
      t.integer :occurrences, null: false, default: 0
    end
  end
end
