# frozen_string_literal: true

class SitesSupporter < ApplicationRecord
  # ==== Associations ====
  belongs_to :supporter
  belongs_to :site

  # ==== Validations ====
  validates :supporter_id,
            uniqueness: { scope: :site_id,
                          message: 'Supporters can not be assigned more than once to a site' }
end
