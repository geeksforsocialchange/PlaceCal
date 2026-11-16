# frozen_string_literal: true

class AddFeedEmptySinceToCalendars < ActiveRecord::Migration[8.1]
  def change
    add_column :calendars, :feed_empty_since, :datetime
  end
end
