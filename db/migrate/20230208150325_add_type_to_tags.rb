# frozen_string_literal: true

class AddTypeToTags < ActiveRecord::Migration[6.1]
  def change
    add_column :tags, :type, :string, default: 'FacilityTag'
  end
end
