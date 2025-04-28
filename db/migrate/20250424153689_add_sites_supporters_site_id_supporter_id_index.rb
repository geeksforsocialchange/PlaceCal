# frozen_string_literal: true

class AddSitesSupportersSiteIdSupporterIdIndex < ActiveRecord::Migration[7.2]
  def change
    add_index :sites_supporters, %w[site_id supporter_id], name: :index_sites_supporters_site_id_supporter_id, unique: true
  end
end
