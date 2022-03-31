class AddAuthorToArticle < ActiveRecord::Migration[6.1]
  def change
    add_column :articles, :author, :string
  end
end
