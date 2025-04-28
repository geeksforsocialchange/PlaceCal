# frozen_string_literal: true

class ChangeArticlePartnersPartnerIdNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :article_partners, :partner_id, false
  end
end
