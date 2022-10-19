# frozen_string_literal: true

class AddEditPermissionToTags < ActiveRecord::Migration[6.1]
  def change
    add_column :tags, :edit_permission, :string
  end
end
