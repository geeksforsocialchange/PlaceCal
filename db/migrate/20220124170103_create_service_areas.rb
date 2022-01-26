class CreateServiceAreas < ActiveRecord::Migration[6.1]
  def change
    create_table :service_areas do |t|
      t.references :neighbourhood, foreign_key: true
      t.references :partner, foreign_key: true

      t.timestamps
    end

    add_index :service_areas, %i[neighbourhood_id partner_id], unique: true
  end
end
