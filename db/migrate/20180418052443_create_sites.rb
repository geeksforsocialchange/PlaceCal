class CreateSites < ActiveRecord::Migration[5.1]
  def change
    create_table :sites do |t|
    	t.string :name
      t.string :slug
      t.string :domain
      t.text :description

      t.timestamps
    end
  end
end
