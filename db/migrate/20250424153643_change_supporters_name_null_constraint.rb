# frozen_string_literal: true

class ChangeSupportersNameNullConstraint < ActiveRecord::Migration[7.2]
  def change
    # Use 4-arg version to set a default for any existing NULL values
    change_column_null :supporters, :name, false, 'Unknown'
  end
end
