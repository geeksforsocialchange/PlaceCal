# frozen_string_literal: true

# Calendars whose feed already went empty skip it as unchanged; one fresh read starts their empty-feed record
class ClearCalendarChecksums < ActiveRecord::Migration[8.1]
  def up
    safety_assured { execute 'UPDATE calendars SET last_checksum = NULL' }
  end

  def down; end
end
