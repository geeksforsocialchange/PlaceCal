# frozen_string_literal: true

class AddPublishToSites < ActiveRecord::Migration[6.0]
  def change
    add_column :sites, :is_published, :boolean, default: false
  end
end
