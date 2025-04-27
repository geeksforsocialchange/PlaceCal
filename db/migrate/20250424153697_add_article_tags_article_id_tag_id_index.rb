# frozen_string_literal: true

class AddArticleTagsArticleIdTagIdIndex < ActiveRecord::Migration[7.2]
  def change
    add_index :article_tags, %w[article_id tag_id], name: :index_article_tags_article_id_tag_id, unique: true
  end
end
