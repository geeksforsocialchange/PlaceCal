# frozen_string_literal: true

# == Schema Information
#
# Table name: sites_supporters
#
#  site_id      :bigint           not null
#  supporter_id :bigint           not null
#
# Indexes
#
#  index_sites_supporters_on_supporter_id_and_site_id  (supporter_id,site_id)
#  index_sites_supporters_site_id_supporter_id         (site_id,supporter_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (site_id => sites.id)
#  fk_rails_...  (supporter_id => supporters.id)
#
class SitesSupporter < ApplicationRecord
  # ==== Associations ====
  belongs_to :supporter
  belongs_to :site

  # ==== Validations ====
  validates :supporter_id,
            uniqueness: { scope: :site_id,
                          message: 'Supporters can not be assigned more than once to a site' }
end
