# frozen_string_literal: true

class AddDefaultFalseToIsDraftInArticles < ActiveRecord::Migration[7.2]
  def change
    change_column_default :articles, :is_draft, from: nil, to: false
  end
end
