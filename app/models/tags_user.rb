# frozen_string_literal: true

# == Schema Information
#
# Table name: tags_users
#
#  id      :bigint           not null, primary key
#  tag_id  :bigint           not null
#  user_id :bigint           not null
#
# Indexes
#
#  index_tags_users_on_user_id_and_tag_id  (user_id,tag_id)
#  index_tags_users_tag_id_user_id         (tag_id,user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (tag_id => tags.id)
#  fk_rails_...  (user_id => users.id)
#
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
