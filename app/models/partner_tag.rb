# frozen_string_literal: true

class PartnerTag < ApplicationRecord
  belongs_to :partner
  belongs_to :tag
  validates :tag_id,
            uniqueness: {
              scope: :partner_id,
              message: 'User cannot be assigned more than once to a tag'
            }
end
