# frozen_string_literal: true

# == Schema Information
#
# Table name: sites_tags
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  site_id    :bigint           not null
#  tag_id     :bigint           not null
#
# Indexes
#
#  index_sites_tags_on_site_id_and_tag_id  (site_id,tag_id) UNIQUE
#  index_sites_tags_on_tag_id              (tag_id)
#
# Foreign Keys
#
#  fk_rails_...  (site_id => sites.id)
#  fk_rails_...  (tag_id => tags.id)
#
class SitesTag < ApplicationRecord
  # ==== Associations ====
  belongs_to :tag
  belongs_to :site

  # ==== Validations ====
  validates :tag_id,
            uniqueness: {
              scope: :site_id,
              message: 'Site cannot be assigned more than once to a tag'
            }
end
