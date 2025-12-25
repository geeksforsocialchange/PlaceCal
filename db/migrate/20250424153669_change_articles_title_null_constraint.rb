# frozen_string_literal: true

class ChangeArticlesTitleNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :articles, :title, false
  end
end
