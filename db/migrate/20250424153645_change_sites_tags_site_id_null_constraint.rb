# frozen_string_literal: true

class ChangeSitesTagsSiteIdNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :sites_tags, :site_id, false
  end
end
