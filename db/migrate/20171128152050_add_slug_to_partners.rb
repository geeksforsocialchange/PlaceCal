# frozen_string_literal: true

class AddSlugToPartners < ActiveRecord::Migration[5.1]
  def change
    add_column :partners, :slug, :string
    add_index :partners, :slug, unique: true
  end
end
