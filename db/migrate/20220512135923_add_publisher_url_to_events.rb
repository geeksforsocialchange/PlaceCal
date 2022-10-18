# frozen_string_literal: true

class AddPublisherUrlToEvents < ActiveRecord::Migration[6.1]
  def change
    add_column :events, :publisher_url, :string
  end
end
