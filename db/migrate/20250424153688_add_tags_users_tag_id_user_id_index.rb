# frozen_string_literal: true

class AddTagsUsersTagIdUserIdIndex < ActiveRecord::Migration[7.2]
  def change
    add_index :tags_users, %w[tag_id user_id], name: :index_tags_users_tag_id_user_id, unique: true
  end
end
