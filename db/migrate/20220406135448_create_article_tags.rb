# frozen_string_literal: true

class CreateArticleTags < ActiveRecord::Migration[6.1]
  def change
    create_table :article_tags do |t|
      t.belongs_to :article
      t.belongs_to :tag

      t.timestamps
    end
  end
end
