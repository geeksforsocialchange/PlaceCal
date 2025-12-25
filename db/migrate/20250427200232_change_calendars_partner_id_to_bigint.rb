# frozen_string_literal: true

class ChangeCalendarsPartnerIdToBigint < ActiveRecord::Migration[7.2]
  def up
    change_column :calendars, :partner_id, :bigint
  end

  def down
    change_column :calendars, :partner_id, :integer
  end
end
