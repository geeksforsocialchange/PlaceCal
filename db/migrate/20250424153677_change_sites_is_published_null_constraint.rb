# frozen_string_literal: true

class ChangeSitesIsPublishedNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :sites, :is_published, false
  end
end
