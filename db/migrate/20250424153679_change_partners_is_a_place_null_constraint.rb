# frozen_string_literal: true

class ChangePartnersIsAPlaceNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :partners, :is_a_place, false
  end
end
