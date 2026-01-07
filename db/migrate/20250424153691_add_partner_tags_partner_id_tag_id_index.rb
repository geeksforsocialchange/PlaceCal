# frozen_string_literal: true

class AddPartnerTagsPartnerIdTagIdIndex < ActiveRecord::Migration[7.2]
  def change
    add_index :partner_tags, %w[partner_id tag_id], name: :index_partner_tags_partner_id_tag_id, unique: true
  end
end
