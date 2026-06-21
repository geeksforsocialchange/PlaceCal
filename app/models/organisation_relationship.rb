# frozen_string_literal: true

# == Schema Information
#
# Table name: organisation_relationships
#
#  id                 :bigint           not null, primary key
#  verb               :string           not null
#  partner_object_id  :bigint           not null
#  partner_subject_id :bigint           not null
#
# Indexes
#
#  index_organisation_relationships_on_partner_object_id  (partner_object_id)
#  unique_organisation_relationship_row                   (partner_subject_id,verb,partner_object_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (partner_object_id => partners.id)
#  fk_rails_...  (partner_subject_id => partners.id)
#
class OrganisationRelationship < ApplicationRecord
  # NOTE: This model is (was) used to define a relationship between
  #   partners so one "big" partner can have lots of "small" partners "within"
  #   the code here is preserved to maintain active functionality on the production
  #   site but please note there is no way for admins to operate on this data
  #   directly.
  #   we hope to define this relationship properly later on and remove this
  #   confusing model but leaving as is for now -IK

  # ==== Includes / Extends ====
  extend Enumerize

  # ==== Enums / Enumerize ====
  enumerize :verb, in: %i[manages]
  # verb -- managed by enumerize, attribute declaration skipped

  # ==== Associations ====
  # rubocop:disable Rails/InverseOf
  belongs_to :subject, class_name: 'Partner', foreign_key: 'partner_subject_id'
  belongs_to :object, class_name: 'Partner', foreign_key: 'partner_object_id'
  # rubocop:enable Rails/InverseOf
end
