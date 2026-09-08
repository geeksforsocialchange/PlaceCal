# frozen_string_literal: true

class AddImageCreditAndPullQuoteToArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :image_credit, :string
    add_column :articles, :pull_quote, :text
  end
end
