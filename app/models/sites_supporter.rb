# frozen_string_literal: true

# app/models/sites_supporter.rb
class SitesSupporter < ApplicationRecord
  belongs_to :supporter
  belongs_to :site
  validates_uniqueness_of :supporter_id,
                          scope: :site_id,
                          message: 'Supporters can not be assigned more than once to a site'
end
