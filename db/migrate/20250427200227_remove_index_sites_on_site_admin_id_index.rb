# frozen_string_literal: true

class RemoveIndexSitesOnSiteAdminIdIndex < ActiveRecord::Migration[7.2]
  def up
    remove_index 'sites', name: 'index_sites_on_site_admin_id'
  end

  def down
    add_index 'sites', :site_admin_id, name: 'index_sites_on_site_admin_id'
  end
end
