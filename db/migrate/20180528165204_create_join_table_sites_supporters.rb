class CreateJoinTableSitesSupporters < ActiveRecord::Migration[5.1]
  def change
    create_join_table :sites, :supporters do |t|
      t.index %i[site_id supporter_id]
      t.index %i[supporter_id site_id]
    end
  end
end
