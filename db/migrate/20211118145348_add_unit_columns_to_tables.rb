# frozen_string_literal: true

class AddUnitColumnsToTables < ActiveRecord::Migration[6.0]
  def change
    change_table(:neighbourhoods, bulk: true) do |n|
      n.column :unit,            :string, default: 'ward'
      n.column :unit_code_key,   :string, default: 'WD19CD'
      n.column :unit_code_value, :string
      n.column :unit_name,       :string
    end
  end
end
