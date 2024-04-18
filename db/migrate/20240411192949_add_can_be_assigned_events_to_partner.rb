# frozen_string_literal: true

class AddCanBeAssignedEventsToPartner < ActiveRecord::Migration[7.1]
  def change
    add_column :partners, :can_be_assigned_events, :boolean, default: false
  end
end
