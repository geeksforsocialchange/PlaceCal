# frozen_string_literal: true

class OrganisationRelationship < ApplicationRecord
  self.table_name = 'organisation_relationships'

  belongs_to :subject, class_name: 'Partner'
  extend Enumerize
  enumerize :verb, in: %i[manages]
  belongs_to :object, class_name: 'Partner'
end
