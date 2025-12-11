# frozen_string_literal: true

class ChangeCalendarsSourceNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :calendars, :source, false
  end
end
