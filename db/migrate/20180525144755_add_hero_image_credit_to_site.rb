# frozen_string_literal: true

class AddHeroImageCreditToSite < ActiveRecord::Migration[5.1]
  def change
    add_column :sites, :hero_image_credit, :string
  end
end
