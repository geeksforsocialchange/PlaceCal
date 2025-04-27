# frozen_string_literal: true

class ChangeTagsSystemTagNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :tags, :system_tag, false
  end
end
