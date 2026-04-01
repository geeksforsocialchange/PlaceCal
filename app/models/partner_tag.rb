# frozen_string_literal: true

class PartnerTag < ApplicationRecord
  # -- Associations --
  belongs_to :partner
  belongs_to :tag

  # -- Validations --
  validates :tag_id,
            uniqueness: {
              scope: :partner_id,
              message: 'User cannot be assigned more than once to a tag'
            }
end
