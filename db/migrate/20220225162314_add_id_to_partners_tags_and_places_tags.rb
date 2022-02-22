class AddIdToPartnersTagsAndPlacesTags < ActiveRecord::Migration[6.1]
  def change
    rename_table :partners_tags, :partner_tags
    add_column :partner_tags, :id, :primary_key

    # I think the places_tags table got leftover after
    # the places => partners(inc. places} migration ages ago
    drop_table :places_tags
  end
end
