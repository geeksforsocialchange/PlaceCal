# frozen_string_literal: true

class AddPartnersIdPartnerTagsPartnerIdFk < ActiveRecord::Migration[7.2]
  def change
    add_foreign_key :partner_tags, :partners, column: :partner_id, primary_key: :id
  end
end
