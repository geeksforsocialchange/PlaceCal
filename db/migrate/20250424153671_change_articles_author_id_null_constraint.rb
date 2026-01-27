# frozen_string_literal: true

class ChangeArticlesAuthorIdNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :articles, :author_id, false
  end
end
