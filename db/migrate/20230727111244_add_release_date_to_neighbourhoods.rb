# frozen_string_literal: true

class AddReleaseDateToNeighbourhoods < ActiveRecord::Migration[6.1]
  def change
    add_column :neighbourhoods, :release_date, :datetime
  end
end
