class SplitTurfsIntoNeighbourhoodsAndTurfs < ActiveRecord::Migration[5.1]
  def up
    #1 Create and populate neighbourhoods table
    create_table :neighbourhoods do |t|
      t.string :name
    end
    execute(
      "insert into neighbourhoods ( id, name ) select id, name from turfs where turfs.turf_type = 'neighbourhood';"
    )

    #2 Change addresses to point at neighbourhoods rather than turfs
    remove_foreign_key :addresses, column: :neighbourhood_turf_id
    rename_column :addresses, :neighbourhood_turf_id, :neighbourhood_id
    add_foreign_key :addresses, :neighbourhoods, column: :neighbourhood_id

    #3 Rename sites_turfs
    rename_table :sites_turfs, :sites_neighbourhoods
    rename_column :sites_neighbourhoods, :turf_id, :neighbourhood_id

    #4 Delete redundant data and structure from turfs
    execute("delete from turfs where turf_type = 'neighbourhood';")
    remove_column :turfs, :turf_type, :string
  end

  def down
    #4
    add_column :turfs, :turf_type, :string
    execute("update turfs set turf_type = 'interest';")
    # Note: Does not create slugs for neighbourhood turfs!
    execute(
      "insert into turfs ( id, name, turf_type, created_at, updated_at ) select id, name, 'neighbourhood', now(), now() from neighbourhoods;"
    )

    #3
    rename_table :sites_neighbourhoods, :sites_turfs
    rename_column :sites_turfs, :neighbourhood_id, :turf_id

    #2
    remove_foreign_key :addresses, :neighbourhoods
    rename_column :addresses, :neighbourhood_id, :neighbourhood_turf_id
    add_foreign_key :addresses, :turfs, column: :neighbourhood_turf_id

    #3
    drop_table :neighbourhoods
  end
end
