# frozen_string_literal: true

class AddTagsIdTagsUsersTagIdFk < ActiveRecord::Migration[7.2]
  def change
    add_foreign_key :tags_users, :tags, column: :tag_id, primary_key: :id
  end
end
