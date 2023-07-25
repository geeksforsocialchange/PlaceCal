# frozen_string_literal: true

class AddHeroTextToSite < ActiveRecord::Migration[6.1]
  def change
    add_column :sites, :hero_text, :string
  end
end
