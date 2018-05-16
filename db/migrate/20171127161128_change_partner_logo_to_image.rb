# frozen_string_literal: true

class ChangePartnerLogoToImage < ActiveRecord::Migration[5.1]
  def change
    rename_column :partners, :logo, :image
  end
end
