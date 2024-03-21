# frozen_string_literal: true

class HeroAlttext < ActiveRecord::Migration[7.1]
  def change
    add_column :sites, :hero_alttext, :string
  end
end
