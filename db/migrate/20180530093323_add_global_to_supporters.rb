# frozen_string_literal: true

class AddGlobalToSupporters < ActiveRecord::Migration[5.1]
  def change
    add_column :supporters, :is_global, :boolean, default: false
  end
end
