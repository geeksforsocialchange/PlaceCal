# frozen_string_literal: true

class AddEventsPartnerIdIndex < ActiveRecord::Migration[7.2]
  def change
    add_index :events, :partner_id, name: :index_events_partner_id
  end
end
