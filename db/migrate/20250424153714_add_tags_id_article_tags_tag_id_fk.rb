# frozen_string_literal: true

class AddTagsIdArticleTagsTagIdFk < ActiveRecord::Migration[7.2]
  def change
    add_foreign_key :article_tags, :tags, column: :tag_id, primary_key: :id
  end
end
