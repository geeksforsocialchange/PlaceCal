# frozen_string_literal: true

class PartnerHiddenReason < ActiveRecord::Migration[6.1]
  def change
    add_column :partners, :hidden_reason, :text
  end
end
