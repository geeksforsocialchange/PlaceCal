# frozen_string_literal: true

class RemoveIndexArticleTagsOnArticleIdIndex < ActiveRecord::Migration[7.2]
  def up
    remove_index 'article_tags', name: 'index_article_tags_on_article_id'
  end

  def down
    add_index 'article_tags', :article_id, name: 'index_article_tags_on_article_id'
  end
end
