# frozen_string_literal: true

class ChangeArticlesIsDraftNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :articles, :is_draft, false
  end
end
