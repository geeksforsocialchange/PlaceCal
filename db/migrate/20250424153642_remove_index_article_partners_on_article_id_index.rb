# frozen_string_literal: true

class RemoveIndexArticlePartnersOnArticleIdIndex < ActiveRecord::Migration[7.2]
  def change
    reversible do |dir|
      dir.up   { remove_index 'article_partners', name: 'index_article_partners_on_article_id' }
      dir.down { add_index 'article_partners', :site_id, name: 'index_article_partners_on_article_id' }
    end
  end
end
