# frozen_string_literal: true

class AddSitesSiteAdminIndex < ActiveRecord::Migration[7.2]
  def change
    add_index :sites, :site_admin_id, name: :index_sites_site_admin
  end
end
