# frozen_string_literal: true

class ChangeSupportersIsGlobalNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :supporters, :is_global, false
  end
end
