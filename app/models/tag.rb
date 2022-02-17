# frozen_string_literal: true

class Tag < ApplicationRecord
  extend FriendlyId
  extend Enumerize

  friendly_id :name, use: :slugged

  self.table_name = 'tags' # Maybe we can remove this? Tag should automagically railsify to tags right?

  has_and_belongs_to_many :users
  has_and_belongs_to_many :partners

  validates :name, :slug, presence: true
  validates :name, :slug, uniqueness: true
  validates :description,
            length: {
              maximum: 200,
              too_long: 'maximum length is 200 characters'
            }
  validates :edit_permission, presence: true

  enumerize :edit_permission,
            in: %i[root all],
            default: :root
end
