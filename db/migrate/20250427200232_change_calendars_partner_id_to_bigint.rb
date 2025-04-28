# frozen_string_literal: true

class ChangeCalendarsPartnerIdToBigint < ActiveRecord::Migration[7.2]
  def change
    reversible do |dir|
      dir.up do
        change_column :calendars, :partner_id, :bigint
      end

      dir.down do
        change_column :calendars, :partner_id, :integer
      end
    end
  end
end
