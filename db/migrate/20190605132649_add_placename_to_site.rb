# frozen_string_literal: true

class AddPlacenameToSite < ActiveRecord::Migration[5.1]
  def change
    add_column :sites, :place_name, :string
  end
end
