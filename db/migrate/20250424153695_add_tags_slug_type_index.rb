# frozen_string_literal: true

class AddTagsSlugTypeIndex < ActiveRecord::Migration[7.2]
  def change
    add_index :tags, %w[slug type], name: :index_tags_slug_type, unique: true
  end
end
