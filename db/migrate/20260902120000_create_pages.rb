# frozen_string_literal: true

# Static per-site content pages (#3368, D5). Partnerships need their own
# About/Privacy style copy without shipping site-specific views, so pages are a
# core model routed at /:slug and edited in admin by the site's admin.
class CreatePages < ActiveRecord::Migration[8.0]
  def change
    create_table :pages do |t|
      t.references :site, null: false, foreign_key: true, index: true
      t.string :slug, null: false
      t.string :title, null: false
      t.text :body
      t.text :body_html
      t.integer :position, null: false, default: 0
      t.boolean :show_in_nav, null: false, default: false
      t.boolean :is_published, null: false, default: false

      t.timestamps
    end

    add_index :pages, %i[site_id slug], unique: true
  end
end
