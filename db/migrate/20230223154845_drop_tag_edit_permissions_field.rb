# frozen_string_literal: true

class DropTagEditPermissionsField < ActiveRecord::Migration[6.1]
  def change
    remove_column :tags, :edit_permission, :string, default: :all
  end
end
