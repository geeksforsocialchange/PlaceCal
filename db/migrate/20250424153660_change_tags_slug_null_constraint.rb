# frozen_string_literal: true

class ChangeTagsSlugNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :tags, :slug, false
  end
end
