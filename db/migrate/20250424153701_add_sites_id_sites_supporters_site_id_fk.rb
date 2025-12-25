# frozen_string_literal: true

class AddSitesIdSitesSupportersSiteIdFk < ActiveRecord::Migration[7.2]
  def change
    add_foreign_key :sites_supporters, :sites, column: :site_id, primary_key: :id
  end
end
