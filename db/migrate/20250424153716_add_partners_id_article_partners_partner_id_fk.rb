# frozen_string_literal: true

class AddPartnersIdArticlePartnersPartnerIdFk < ActiveRecord::Migration[7.2]
  def change
    add_foreign_key :article_partners, :partners, column: :partner_id, primary_key: :id
  end
end
