# frozen_string_literal: true

class Tag < ApplicationRecord
  extend FriendlyId
  extend Enumerize

  friendly_id :name, use: :slugged

  self.table_name = 'tags' # Maybe we can remove this? Tag should automagically railsify to tags right?

  has_and_belongs_to_many :partners

  has_many :tags_users, dependent: :destroy
  has_many :users, through: :tags_users

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

  def self.edit_permission_label(value)
    case value.second
    when 'root'
      '<strong>Root</strong>: Only root-level users may assign this tag'.html_safe
    when 'all'
      '<strong>All</strong>: Any user may assign this tag'.html_safe
    else
      value
    end
  end
end
