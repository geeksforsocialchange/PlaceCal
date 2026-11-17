# frozen_string_literal: true

class AddSourceCategoriesAndOrganiserToEvents < ActiveRecord::Migration[8.1]
  # Separate add_columns so strong_migrations can check each; it can't see inside change_table
  def change
    add_column :events, :source_categories, :jsonb # rubocop:disable Rails/BulkChangeTable
    add_column :events, :source_organiser, :string
  end
end
