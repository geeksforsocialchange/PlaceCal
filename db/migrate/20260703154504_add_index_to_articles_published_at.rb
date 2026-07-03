# frozen_string_literal: true

# Every public news listing and feed orders by published_at (issue #3308).
class AddIndexToArticlesPublishedAt < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :articles, :published_at, algorithm: :concurrently
  end
end
