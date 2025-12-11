# frozen_string_literal: true

class AddSitesSlugIndex < ActiveRecord::Migration[7.2]
  def change
    # Unique index for URL routing lookups via find_by_request
    add_index :sites, :slug, unique: true, name: 'index_sites_slug'
  end
end
