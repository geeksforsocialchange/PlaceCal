# frozen_string_literal: true

class CreatePartnershipBroadcasts < ActiveRecord::Migration[8.1]
  def change
    create_table :partnership_broadcasts do |t|
      t.references :partnership, null: false, foreign_key: { to_table: :tags }
      # Nullable so the sent-broadcasts log survives sender account erasure
      t.references :sender, foreign_key: { to_table: :users }
      t.string :subject, null: false
      t.text :body, null: false
      t.integer :recipient_count, null: false, default: 0
      t.integer :excluded_count, null: false, default: 0

      t.timestamps
    end
  end
end
