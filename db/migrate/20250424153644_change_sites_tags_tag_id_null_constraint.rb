# frozen_string_literal: true

class ChangeSitesTagsTagIdNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :sites_tags, :tag_id, false
  end
end
