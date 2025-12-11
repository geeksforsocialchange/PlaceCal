# frozen_string_literal: true

class ChangeCalendarsNameNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :calendars, :name, false
  end
end
