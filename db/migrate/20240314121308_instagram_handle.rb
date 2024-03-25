# frozen_string_literal: true

class InstagramHandle < ActiveRecord::Migration[7.1]
  def change
    add_column :partners, :instagram_handle, :string
  end
end
