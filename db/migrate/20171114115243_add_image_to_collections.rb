# frozen_string_literal: true

class AddImageToCollections < ActiveRecord::Migration[5.1]
  def change
    add_column :collections, :image, :string
  end
end
