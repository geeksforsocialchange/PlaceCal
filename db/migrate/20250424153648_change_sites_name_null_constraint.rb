# frozen_string_literal: true

class ChangeSitesNameNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :sites, :name, false
  end
end
