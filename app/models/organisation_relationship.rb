# frozen_string_literal: true

class OrganisationRelationship < ApplicationRecord
  # NOTE: This model is (was) used to define a relationship between
  #   partners so one "big" partner can have lots of "small" partners "within"
  #   the code here is preserved to maintain active functionality on the production
  #   site but please note there is no way for admins to operate on this data
  #   directly.
  #   we hope to define this relationship properly later on and remove this
  #   confusing model but leaving as is for now -IK

  # rubocop:disable Rails/InverseOf
  belongs_to :subject, class_name: 'Partner', foreign_key: 'partner_subject_id'
  belongs_to :object, class_name: 'Partner', foreign_key: 'partner_object_id'
  # rubocop:enable Rails/InverseOf

  extend Enumerize
  enumerize :verb, in: %i[manages]
end
