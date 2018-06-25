# frozen_string_literal: true

# app/models/sites_turf.rb
class SitesTurf < ApplicationRecord
  self.table_name = 'sites_turfs'
  belongs_to :turf
  belongs_to :site
  validates_uniqueness_of :turf_id, scope: :site_id, message: 'Turf can not be assigned more than once to a site'
end
