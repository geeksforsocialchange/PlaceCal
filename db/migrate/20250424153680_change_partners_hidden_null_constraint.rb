# frozen_string_literal: true

class ChangePartnersHiddenNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :partners, :hidden, false
  end
end
