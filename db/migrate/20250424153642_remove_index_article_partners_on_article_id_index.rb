# frozen_string_literal: true

class RemoveIndexArticlePartnersOnArticleIdIndex < ActiveRecord::Migration[7.2]
  def change
    # remove_index 'article_partners', name: 'index_article_partners_on_article_id'
    remove_index :article, :partners
  end
end
