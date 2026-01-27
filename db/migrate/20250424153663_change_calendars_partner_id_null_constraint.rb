# frozen_string_literal: true

class ChangeCalendarsPartnerIdNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :calendars, :partner_id, false
  end
end
