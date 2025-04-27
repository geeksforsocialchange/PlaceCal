# frozen_string_literal: true

class ChangePartnersCanBeAssignedEventsNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :partners, :can_be_assigned_events, false
  end
end
