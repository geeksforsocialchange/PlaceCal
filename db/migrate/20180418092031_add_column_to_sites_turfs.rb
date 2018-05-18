# frozen_string_literal: true

class AddColumnToSitesTurfs < ActiveRecord::Migration[5.1]
  def change
    add_column :sites_turfs, :relation_type, :string
  end
end
