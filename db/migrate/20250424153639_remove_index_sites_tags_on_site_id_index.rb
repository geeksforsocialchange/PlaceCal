# frozen_string_literal: true

class RemoveIndexSitesTagsOnSiteIdIndex < ActiveRecord::Migration[7.2]
  def change
    # remove_index 'sites_tags', name: 'index_sites_tags_on_site_id'
    remove_index :sites, :tags
  end
end
