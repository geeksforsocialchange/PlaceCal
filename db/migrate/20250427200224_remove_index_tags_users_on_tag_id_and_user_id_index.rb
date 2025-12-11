# frozen_string_literal: true

class RemoveIndexTagsUsersOnTagIdAndUserIdIndex < ActiveRecord::Migration[7.2]
  def up
    remove_index 'tags_users', name: 'index_tags_users_on_tag_id_and_user_id'
  end

  def down
    add_index 'tags_users', %i[tag_id user_id], name: 'index_tags_users_on_tag_id_and_user_id'
  end
end
