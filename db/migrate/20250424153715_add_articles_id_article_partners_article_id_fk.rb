# frozen_string_literal: true

class AddArticlesIdArticlePartnersArticleIdFk < ActiveRecord::Migration[7.2]
  def change
    add_foreign_key :article_partners, :articles, column: :article_id, primary_key: :id
  end
end
