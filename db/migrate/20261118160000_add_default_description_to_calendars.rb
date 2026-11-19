# frozen_string_literal: true

class AddDefaultDescriptionToCalendars < ActiveRecord::Migration[8.1]
  def change
    add_column :calendars, :default_description, :text
  end
end
