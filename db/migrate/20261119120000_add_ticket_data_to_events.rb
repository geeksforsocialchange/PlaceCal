# frozen_string_literal: true

class AddTicketDataToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :ticket_url, :string
    add_column :events, :price_from, :decimal, precision: 10, scale: 2
    add_column :events, :price_currency, :string
    add_column :events, :sold_out, :boolean
  end
end
