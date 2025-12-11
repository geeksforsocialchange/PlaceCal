# frozen_string_literal: true

class ChangeEventsSummaryNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :events, :summary, false
  end
end
