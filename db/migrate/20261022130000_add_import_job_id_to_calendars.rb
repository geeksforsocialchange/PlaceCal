# frozen_string_literal: true

class AddImportJobIdToCalendars < ActiveRecord::Migration[8.1]
  def change
    add_column :calendars, :import_job_id, :bigint
  end
end
