# frozen_string_literal: true

class ChangeEventsPartnerIdToBigint < ActiveRecord::Migration[7.2]
  def up
    change_column :events, :partner_id, :bigint
  end

  def down
    change_column :events, :partner_id, :integer
  end
end
