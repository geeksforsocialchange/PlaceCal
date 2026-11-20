# frozen_string_literal: true

class AddTicketDataToEvents < ActiveRecord::Migration[8.1]
  def change
    # New nullable columns rewrite nothing, and the constraint on one of them has no rows to scan
    safety_assured do
      change_table :events, bulk: true do |t|
        t.string :ticket_url
        t.decimal :price_from, precision: 10, scale: 2
        t.string :price_currency
        t.boolean :sold_out
      end
      add_check_constraint :events, 'price_from >= 0', name: 'events_price_from_not_negative'
    end
  end
end
