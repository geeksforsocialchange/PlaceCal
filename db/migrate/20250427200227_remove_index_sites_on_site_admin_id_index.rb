# frozen_string_literal: true

class RemoveIndexSitesOnSiteAdminIdIndex < ActiveRecord::Migration[7.2]
  def change
    reversible do |dir|
      dir.up do
        remove_index 'sites', name: 'index_sites_on_site_admin_id'
      end

      dir.down do
        add_index 'sites', :site_admin_id, name: 'index_sites_on_site_admin_id'
      end
    end
  end
end
