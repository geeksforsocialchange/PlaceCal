# frozen_string_literal: true

class DropUnusedImporterColumns < ActiveRecord::Migration[8.1]
  def change
    # Both columns are in ignored_columns on the deployed code, so no running process reads or writes them
    safety_assured do
      remove_column :calendars, :is_working, :boolean, default: true, null: false
      remove_column :events, :notices, :jsonb
    end
  end
end
