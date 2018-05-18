# frozen_string_literal: true

class AddAreSpacesAvailableToEvents < ActiveRecord::Migration[5.1]
  def change
    add_column :events, :are_spaces_available, :string
  end
end
