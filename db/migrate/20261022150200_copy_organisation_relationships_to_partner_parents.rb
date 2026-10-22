# frozen_string_literal: true

# Each "manages" row becomes the managed partner's parent.
class CopyOrganisationRelationshipsToPartnerParents < ActiveRecord::Migration[8.1]
  def up
    safety_assured do
      execute <<~SQL.squish
        UPDATE partners
        SET parent_id = o_r.partner_subject_id
        FROM organisation_relationships o_r
        WHERE o_r.partner_object_id = partners.id
          AND o_r.verb = 'manages'
          AND o_r.partner_subject_id <> o_r.partner_object_id
          AND partners.parent_id IS NULL
      SQL
    end
  end

  def down
    safety_assured { execute 'UPDATE partners SET parent_id = NULL' }
  end
end
