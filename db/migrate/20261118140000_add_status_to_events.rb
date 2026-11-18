# frozen_string_literal: true

class AddStatusToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :status, :string, null: false, default: 'scheduled'
  end
end
