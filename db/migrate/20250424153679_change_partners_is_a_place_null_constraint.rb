# frozen_string_literal: true

class ChangePartnersIsAPlaceNullConstraint < ActiveRecord::Migration[7.2]
  def change
    # Use 4-arg version to update NULL values to false before adding constraint
    change_column_null :partners, :is_a_place, false, false
  end
end
