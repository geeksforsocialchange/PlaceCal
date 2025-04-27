# frozen_string_literal: true

class AddEventsAddressIdIndex < ActiveRecord::Migration[7.2]
  def change
    add_index :events, :address_id, name: :index_events_address_id
  end
end
