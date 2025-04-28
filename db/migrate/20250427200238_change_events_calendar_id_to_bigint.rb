# frozen_string_literal: true

class ChangeEventsCalendarIdToBigint < ActiveRecord::Migration[7.2]
  def change
    reversible do |dir|
      dir.up do
        change_column :events, :calendar_id, :bigint
      end

      dir.down do
        change_column :events, :calendar_id, :integer
      end
    end
  end
end
