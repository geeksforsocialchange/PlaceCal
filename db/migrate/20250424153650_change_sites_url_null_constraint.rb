# frozen_string_literal: true

class ChangeSitesUrlNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :sites, :url, false
  end
end
