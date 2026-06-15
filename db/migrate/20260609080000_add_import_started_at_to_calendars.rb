# frozen_string_literal: true

class AddImportStartedAtToCalendars < ActiveRecord::Migration[8.1]
  def change
    add_column :calendars, :import_started_at, :datetime
  end
end
