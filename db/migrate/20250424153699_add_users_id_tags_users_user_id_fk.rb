# frozen_string_literal: true

class AddUsersIdTagsUsersUserIdFk < ActiveRecord::Migration[7.2]
  def change
    add_foreign_key :tags_users, :users, column: :user_id, primary_key: :id
  end
end
