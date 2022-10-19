# frozen_string_literal: true

class CreateArticles < ActiveRecord::Migration[6.1]
  def change
    create_table :articles do |t|
      t.text :title
      t.text :body
      t.date :published_at
      t.boolean :is_draft, default: true

      t.timestamps
    end
  end
end
