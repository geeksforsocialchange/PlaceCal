# frozen_string_literal: true

class SitesTag < ApplicationRecord
  # -- Associations --
  belongs_to :tag
  belongs_to :site

  # -- Validations --
  validates :tag_id,
            uniqueness: {
              scope: :site_id,
              message: 'Site cannot be assigned more than once to a tag'
            }
end
