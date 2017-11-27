class AddIsAPlaceToPartner < ActiveRecord::Migration[5.1]
  def change
    add_column :partners, :is_a_place, :boolean
  end
end
