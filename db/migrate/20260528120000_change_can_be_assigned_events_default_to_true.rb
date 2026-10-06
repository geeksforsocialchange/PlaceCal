# frozen_string_literal: true

# Enable event matching by default for new partners.
# See issue #2912: when creating a new partner, event matching should be
# enabled by default rather than disabled.
class ChangeCanBeAssignedEventsDefaultToTrue < ActiveRecord::Migration[8.1]
  def change
    change_column_default :partners, :can_be_assigned_events, from: false, to: true
  end
end
