# frozen_string_literal: true

class ChangeRelations < ActiveRecord::Migration[5.1]
  def change
    drop_table :events_partners do |t|
      t.references :event, foreign_key: true
      t.references :partner, foreign_key: true
    end

    add_column :events, :partner_id, :integer
    add_index :events, :partner_id
    add_column :calendars, :address_id, :integer
    add_index :calendars, :address_id
    add_column :events, :address_id, :integer
    add_index :events, :address_id

    add_foreign_key :events, :partners
    add_foreign_key :calendars, :addresses
    add_foreign_key :events, :addresses
  end
end
