# frozen_string_literal: true

class ChangeSitesSlugNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :sites, :slug, false
  end
end
