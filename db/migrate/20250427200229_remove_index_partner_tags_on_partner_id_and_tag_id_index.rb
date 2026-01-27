# frozen_string_literal: true

class RemoveIndexPartnerTagsOnPartnerIdAndTagIdIndex < ActiveRecord::Migration[7.2]
  def up
    remove_index 'partner_tags', name: 'index_partner_tags_on_partner_id_and_tag_id'
  end

  def down
    add_index 'partner_tags', %i[partner_id tag_id], name: 'index_partner_tags_on_partner_id_and_tag_id'
  end
end
