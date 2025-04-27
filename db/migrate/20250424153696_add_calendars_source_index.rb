# frozen_string_literal: true

class AddCalendarsSourceIndex < ActiveRecord::Migration[7.2]
  def change
    add_index :calendars, :source, name: :index_calendars_source, unique: true
  end
end
