# frozen_string_literal: true

class PartnerHiddenBlame < ActiveRecord::Migration[6.1]
  def change
    add_column :partners, :hidden_blame_id, :integer
  end
end
