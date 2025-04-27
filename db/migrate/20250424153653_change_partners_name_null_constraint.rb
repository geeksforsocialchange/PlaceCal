# frozen_string_literal: true

class ChangePartnersNameNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :partners, :name, false
  end
end
