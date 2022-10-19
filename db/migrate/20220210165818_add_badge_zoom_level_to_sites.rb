# frozen_string_literal: true

class AddBadgeZoomLevelToSites < ActiveRecord::Migration[6.1]
  def change
    add_column :sites, :badge_zoom_level, :string
  end
end
