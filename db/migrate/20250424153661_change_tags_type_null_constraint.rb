# frozen_string_literal: true

class ChangeTagsTypeNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :tags, :type, false
  end
end
