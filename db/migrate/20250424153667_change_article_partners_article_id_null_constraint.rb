# frozen_string_literal: true

class ChangeArticlePartnersArticleIdNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :article_partners, :article_id, false
  end
end
