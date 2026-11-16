# frozen_string_literal: true

# Existing events at their own address still name the default venue; one fresh read of these feeds corrects them
class RereadEventOverrideCalendars < ActiveRecord::Migration[8.1]
  def up
    safety_assured { execute "UPDATE calendars SET last_checksum = NULL WHERE strategy = 'event_override'" }
  end

  def down; end
end
