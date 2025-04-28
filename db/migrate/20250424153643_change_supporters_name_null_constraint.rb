# frozen_string_literal: true

class ChangeSupportersNameNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :supporters, :name, false
  end
end
