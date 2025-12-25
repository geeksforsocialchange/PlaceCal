# frozen_string_literal: true

class ChangeTagsNameNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :tags, :name, false
  end
end
