# frozen_string_literal: true

class AddTagsNameTypeIndex < ActiveRecord::Migration[7.2]
  def change
    add_index :tags, %w[name type], name: :index_tags_name_type, unique: true
  end
end
