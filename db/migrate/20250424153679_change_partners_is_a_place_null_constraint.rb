# frozen_string_literal: true

class ChangePartnersIsAPlaceNullConstraint < ActiveRecord::Migration[7.2]
  # Step 1: Update NULL values to false
  execute <<-SQL.squish
      UPDATE partners
      SET is_a_place = FALSE
      WHERE is_a_place IS NULL;
  SQL

  # Step 2: Add the NOT NULL constraint
  def change
    change_column_null :partners, :is_a_place, false
  end
end
