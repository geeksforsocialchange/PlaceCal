# frozen_string_literal: true

class PartnerHiddenAttribute < ActiveRecord::Migration[6.1]
  def change
    add_column :partners, :hidden, :boolean, default: false
  end
end
