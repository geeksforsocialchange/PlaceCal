# frozen_string_literal: true

class RemoveIndexArticleTagsOnArticleIdIndex < ActiveRecord::Migration[7.2]
  def change
    reversible do |dir|
      dir.up do
        remove_index 'article_tags', name: 'index_article_tags_on_article_id'
      end

      dir.down do
        add_index 'article_tags', :article_id, name: 'index_article_tags_on_article_id'
      end
    end
  end
end
