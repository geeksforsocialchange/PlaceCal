# frozen_string_literal: true

class ChangeEventsDtstartNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :events, :dtstart, false
  end
end
