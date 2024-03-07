# frozen_string_literal: true

class PartnerHiddenReasonHtml < ActiveRecord::Migration[6.1]
  def change
    add_column :partners, :hidden_reason_html, :string
  end
end
