# frozen_string_literal: true

class AddArticlesIdArticleTagsArticleIdFk < ActiveRecord::Migration[7.2]
  def change
    add_foreign_key :article_tags, :articles, column: :article_id, primary_key: :id
  end
end
