# frozen_string_literal: true

class RemoveIndexArticlePartnersOnArticleIdIndex < ActiveRecord::Migration[7.2]
  def up
    remove_index 'article_partners', name: 'index_article_partners_on_article_id'
  end

  def down
    add_index 'article_partners', :article_id, name: 'index_article_partners_on_article_id'
  end
end
