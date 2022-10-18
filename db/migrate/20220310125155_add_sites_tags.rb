# frozen_string_literal: true

class AddSitesTags < ActiveRecord::Migration[6.1]
  def change
    create_table :sites_tags do |t|
      t.references :site, foreign_key: true
      t.references :tag, foreign_key: true

      t.timestamps
    end

    add_index :sites_tags, %i[site_id tag_id], unique: true
  end
end
