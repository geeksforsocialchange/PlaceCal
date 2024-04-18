# frozen_string_literal: true

class PartnerCanBeAssignedEventsSetValue < ActiveRecord::Migration[7.1]
  def up
    Partner.where(can_be_assigned_events: nil).update_all(hidden: false)
  end

  def down; end
end
