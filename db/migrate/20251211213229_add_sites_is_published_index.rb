# frozen_string_literal: true

class AddSitesIsPublishedIndex < ActiveRecord::Migration[7.2]
  def change
    # Index for filtering published sites (scope :published)
    add_index :sites, :is_published, name: 'index_sites_is_published'
  end
end
