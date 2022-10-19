# frozen_string_literal: true

class AddHeroImageToSites < ActiveRecord::Migration[5.1]
  def change
    add_column :sites, :hero_image, :string
  end
end
