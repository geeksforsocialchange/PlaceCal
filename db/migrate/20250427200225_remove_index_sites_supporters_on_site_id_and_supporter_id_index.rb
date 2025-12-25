# frozen_string_literal: true

class RemoveIndexSitesSupportersOnSiteIdAndSupporterIdIndex < ActiveRecord::Migration[7.2]
  def up
    remove_index 'sites_supporters', name: 'index_sites_supporters_on_site_id_and_supporter_id'
  end

  def down
    add_index 'sites_supporters', %i[site_id supporter_id], name: 'index_sites_supporters_on_site_id_and_supporter_id'
  end
end
