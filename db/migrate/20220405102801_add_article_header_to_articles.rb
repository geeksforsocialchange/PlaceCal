class AddArticleHeaderToArticles < ActiveRecord::Migration[6.1]
  def change
    add_column :articles, :article_header, :string
  end
end
