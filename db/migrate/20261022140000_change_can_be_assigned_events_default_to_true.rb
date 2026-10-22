# frozen_string_literal: true

class ChangeCanBeAssignedEventsDefaultToTrue < ActiveRecord::Migration[8.1]
  def change
    change_column_default :partners, :can_be_assigned_events, from: false, to: true
  end
end
