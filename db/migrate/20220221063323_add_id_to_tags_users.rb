class AddIdToTagsUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :tags_users, :id, :primary_key
  end
end
