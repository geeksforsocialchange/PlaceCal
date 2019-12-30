class RenameTurfsToTags < ActiveRecord::Migration[6.0]
  def change
    rename_table :turfs, :tags

    rename_table :partners_turfs, :partners_tags
    rename_column :partners_tags, :turf_id, :tag_id

    rename_table :places_turfs, :places_tags
    rename_column :places_tags, :turf_id, :tag_id

    rename_table :turfs_users, :tags_users
    rename_column :tags_users, :turf_id, :tag_id
  end
end
