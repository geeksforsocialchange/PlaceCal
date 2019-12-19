class CreateNeighbourhoodsUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :neighbourhoods_users do |t|
      t.references :neighbourhood, index: true, foriegn_key: true
      t.references :user, index: true, foriegn_key: true

      t.timestamps null: false
    end
  end
end
