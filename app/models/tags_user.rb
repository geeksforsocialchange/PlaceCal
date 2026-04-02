# frozen_string_literal: true

class TagsUser < ApplicationRecord
  # ==== Constants ====
  self.table_name = 'tags_users'

  # ==== Associations ====
  belongs_to :tag
  belongs_to :user

  # ==== Validations ====
  validates :tag_id,
            uniqueness: {
              scope: :user_id,
              message: 'User cannot be assigned more than once to a tag'
            }
end
