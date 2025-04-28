# frozen_string_literal: true

class RemoveIndexSitesSupportersOnSiteIdAndSupporterIdIndex < ActiveRecord::Migration[7.2]
  def change
    reversible do |dir|
      dir.up do
        remove_index 'sites_supporters', name: 'index_sites_supporters_on_site_id_and_supporter_id'
      end

      dir.down do
        add_index 'sites_supporters', %i[site_id supporter_id], name: 'index_sites_supporters_on_site_id_and_supporter_id'
      end
    end
  end
end
