# frozen_string_literal: true

class ChangeEventsPartnerIdNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :events, :partner_id, false
  end
end
