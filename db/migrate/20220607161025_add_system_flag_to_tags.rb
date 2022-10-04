# frozen_string_literal: true

class AddSystemFlagToTags < ActiveRecord::Migration[6.1]
  def change
    add_column :tags, :system_tag, :boolean, default: false
  end
end
