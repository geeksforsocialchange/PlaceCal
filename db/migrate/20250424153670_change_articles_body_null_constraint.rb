# frozen_string_literal: true

class ChangeArticlesBodyNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :articles, :body, false
  end
end
