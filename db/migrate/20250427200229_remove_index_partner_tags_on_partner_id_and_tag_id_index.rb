# frozen_string_literal: true

class RemoveIndexPartnerTagsOnPartnerIdAndTagIdIndex < ActiveRecord::Migration[7.2]
  def change
    reversible do |dir|
      dir.up do
        remove_index 'partner_tags', name: 'index_partner_tags_on_partner_id_and_tag_id'
      end

      dir.down do
        add_index 'partner_tags', %i[partner_id tag_id], name: 'index_partner_tags_on_partner_id_and_tag_id'
      end
    end
  end
end
