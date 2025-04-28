# frozen_string_literal: true

class RemoveIndexSitesSiteAdminIndex < ActiveRecord::Migration[7.2]
  def change
    reversible do |dir|
      dir.up do
        remove_index 'sites', name: 'index_sites_site_admin'
      end

      dir.down do
        add_index 'sites', :site_admin, name: 'index_sites_site_admin'
      end
    end
  end
end
