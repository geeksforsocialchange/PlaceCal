# frozen_string_literal: true

class AddImportLockAtToCalendar < ActiveRecord::Migration[5.1]
  def change
    add_column :calendars, :import_lock_at, :datetime
  end
end
