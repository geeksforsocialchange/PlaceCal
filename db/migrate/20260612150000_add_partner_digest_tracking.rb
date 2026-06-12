# frozen_string_literal: true

class AddPartnerDigestTracking < ActiveRecord::Migration[8.1]
  def change
    # Interval enforcement is per-user, not per-run (#3256 phase 2)
    add_column :users, :partner_digest_last_sent_at, :datetime

    # Written by the digest's "confirm everything is up to date" link;
    # surfaced in the admin partner index as a staleness indicator
    add_column :partners, :info_confirmed_at, :datetime
    add_column :partners, :info_confirmed_source, :string
    add_reference :partners, :info_confirmed_by, foreign_key: { to_table: :users }
  end
end
