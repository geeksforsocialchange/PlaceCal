# frozen_string_literal: true

class RemoveIndexSitesSiteAdminIndex < ActiveRecord::Migration[7.2]
  def up
    remove_index 'sites', name: 'index_sites_site_admin'
  end

  def down
    add_index 'sites', :site_admin, name: 'index_sites_site_admin'
  end
end
