# frozen_string_literal: true

class RemoveIndexOrganisationRelationshipsOnPartnerSubjectIdIndex < ActiveRecord::Migration[7.2]
  def change
    # remove_index 'organisation_relationships', name: 'index_organisation_relationships_on_partner_subject_id'
    remove_index :organisation_relationships, :partner_subject_id
  end
end
