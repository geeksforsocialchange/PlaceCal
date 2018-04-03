class CreateTurves < ActiveRecord::Migration[5.1]
  def change
    create_table :turves do |t|
      t.string :name
      t.string :slug
      t.string :turf_type
      t.text :description

      t.timestamps
    end
  end
end
