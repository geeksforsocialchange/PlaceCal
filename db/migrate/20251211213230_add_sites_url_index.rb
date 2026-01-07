# frozen_string_literal: true

class AddSitesUrlIndex < ActiveRecord::Migration[7.2]
  def change
    # Index for domain lookup in find_using_domain
    add_index :sites, :url, name: 'index_sites_url'
  end
end
