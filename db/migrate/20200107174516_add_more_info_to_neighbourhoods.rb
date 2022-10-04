# frozen_string_literal: true

class AddMoreInfoToNeighbourhoods < ActiveRecord::Migration[6.0]
  def change
    add_column :neighbourhoods, :name_abbr, :string
    add_column :neighbourhoods, :ward, :string
    add_column :neighbourhoods, :district, :string
    add_column :neighbourhoods, :county, :string
    add_column :neighbourhoods, :region, :string
    add_column :neighbourhoods, :WD19CD, :string
    add_column :neighbourhoods, :WD19NM, :string
    add_column :neighbourhoods, :LAD19CD, :string
    add_column :neighbourhoods, :LAD19NM, :string
    add_column :neighbourhoods, :CTY19CD, :string
    add_column :neighbourhoods, :CTY19NM, :string
    add_column :neighbourhoods, :RGN19CD, :string
    add_column :neighbourhoods, :RGN19NM, :string
  end
end
