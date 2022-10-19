# frozen_string_literal: true

class AddArticleHeaderToArticles < ActiveRecord::Migration[6.1]
  def change
    add_column :articles, :article_image, :string
  end
end
