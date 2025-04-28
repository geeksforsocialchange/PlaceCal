# frozen_string_literal: true

class ChangeEventsPartnerIdToBigint < ActiveRecord::Migration[7.2]
  def change
    reversible do |dir|
      dir.up do
        change_column :events, :partner_id, :bigint
      end

      dir.down do
        change_column :events, :partner_id, :integer
      end
    end
  end
end
