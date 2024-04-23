# frozen_string_literal: true

class CalendarChecksumDate < ActiveRecord::Migration[7.1]
  def up
    add_column :calendars, :checksum_updated_at, :datetime
  end
end
