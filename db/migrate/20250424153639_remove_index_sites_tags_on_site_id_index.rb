# frozen_string_literal: true

class RemoveIndexSitesTagsOnSiteIdIndex < ActiveRecord::Migration[7.2]
  def up
    remove_index :sites_tags, name: 'index_sites_tags_on_site_id'
  end

  def down
    add_index :sites_tags, :site_id, name: 'index_sites_tags_on_site_id'
  end
end
