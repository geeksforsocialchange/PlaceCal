# frozen_string_literal: true

class RemoveAreSpacesAvailableFromEvents < ActiveRecord::Migration[8.1]
  def change
    # Nothing reads or writes the column any more, so code from before this release only fails while containers overlap
    safety_assured { remove_column :events, :are_spaces_available, :string }
  end
end
