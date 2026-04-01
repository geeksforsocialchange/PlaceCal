# frozen_string_literal: true

# Rename partner_id to organiser_id on events and calendars.
# See ADR 0013 for context. Both columns still reference the partners table.
class RenamePartnerToOrganiser < ActiveRecord::Migration[8.1]
  def change
    rename_column :events, :partner_id, :organiser_id
    rename_column :calendars, :partner_id, :organiser_id
  end
end
