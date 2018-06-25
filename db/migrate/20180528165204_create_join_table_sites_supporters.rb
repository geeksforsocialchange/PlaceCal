class CreateJoinTableSitesSupporters < ActiveRecord::Migration[5.1]
  def change
    create_join_table :sites, :supporters do |t|
      t.index [:site_id, :supporter_id]
      t.index [:supporter_id, :site_id]
    end
  end
end
