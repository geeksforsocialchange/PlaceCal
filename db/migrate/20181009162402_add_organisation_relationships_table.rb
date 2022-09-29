class AddOrganisationRelationshipsTable < ActiveRecord::Migration[5.1]
  def change
    create_table :organisation_relationships
    add_reference :organisation_relationships, :subject, null: false
    add_foreign_key :organisation_relationships, :partners, column: :subject_id
    add_column :organisation_relationships, :verb, :string, null: false
    add_reference :organisation_relationships, :object, null: false
    add_foreign_key :organisation_relationships, :partners, column: :object_id
    add_index :organisation_relationships, %i[subject_id verb object_id], unique: true,
                                                                          name: :unique_organisation_relationship_row
  end
end
