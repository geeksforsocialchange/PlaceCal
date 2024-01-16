# frozen_string_literal: true

class RenameOrganisationRelationObjectColumn < ActiveRecord::Migration[6.1]
  def change
    rename_column :organisation_relationships, :object_id, :partner_object_id
    rename_column :organisation_relationships, :subject_id, :partner_subject_id
  end
end
