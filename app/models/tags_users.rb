# frozen_string_literal: true

class TagsUsers < ApplicationRecord
  belongs_to :tag
  belongs_to :user
  validates :tag_id,
            uniqueness: {
              scope: :user_id,
              message: 'User cannot be assigned more than once to a tag'
            }
end
