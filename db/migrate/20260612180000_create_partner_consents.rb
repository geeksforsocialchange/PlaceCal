# frozen_string_literal: true

class CreatePartnerConsents < ActiveRecord::Migration[8.1]
  def change
    # Append-only consent provenance: how/where we got permission to list a
    # partner (#3256 phase 5, from #2256)
    create_table :partner_consents do |t|
      t.references :partner, null: false, foreign_key: true
      t.string :basis, null: false
      t.references :recorded_by, foreign_key: { to_table: :users }

      t.datetime :created_at, null: false
    end

    # Verify-before-visible flow state
    add_column :partners, :verification_invite_sent_at, :datetime
    add_column :partners, :verification_invite_email, :string
    add_column :partners, :verified_at, :datetime
  end
end
