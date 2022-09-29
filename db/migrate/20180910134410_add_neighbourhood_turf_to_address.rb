class AddNeighbourhoodTurfToAddress < ActiveRecord::Migration[5.1]
  def change
    add_reference :addresses, :neighbourhood_turf, foreign_key: { to_table: :turfs }
  end
end
