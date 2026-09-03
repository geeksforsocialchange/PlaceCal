# frozen_string_literal: true

# index_pages_on_site_id is covered by the unique [site_id, slug] index.
class RemoveRedundantPagesSiteIdIndex < ActiveRecord::Migration[8.0]
  def change
    remove_index :pages, name: :index_pages_on_site_id, column: :site_id
  end
end
