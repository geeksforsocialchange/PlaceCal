# frozen_string_literal: true

class AddImageToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :image, :string # rubocop:disable Rails/BulkChangeTable
    add_column :events, :image_source_url, :string
  end
end
