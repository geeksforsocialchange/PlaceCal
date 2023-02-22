# frozen_string_literal: true

class Tag < ApplicationRecord
  extend FriendlyId
  extend Enumerize

  friendly_id :name, use: :slugged

  self.table_name = 'tags' # Maybe we can remove this? Tag should automagically railsify to tags right?

  has_many :tags_users, dependent: :destroy
  has_many :users, through: :tags_users

  has_many :partner_tags, dependent: :destroy
  has_many :partners, through: :partner_tags

  has_many :sites_tag, dependent: :destroy
  has_many :sites, through: :sites_tag

  has_many :article_tags, dependent: :destroy
  has_many :articles, through: :article_tags

  validates :name, :slug, presence: true
  validates :name, :slug, uniqueness: { scope: :type }
  validates :description,
            length: {
              maximum: 200,
              too_long: 'maximum length is 200 characters'
            }
  validates :edit_permission, presence: true
  validate :check_editable_fields

  enumerize :edit_permission,
            in: %i[root all],
            default: :root

  scope :users_tags, lambda { |user|
    tag_ids = user.tags.map(&:id) + Tag.all.where(edit_permission: :all).map(&:id)

    where(id: tag_ids.uniq)
  }

  def name_with_type
    s_type = type || 'Tag'
    "#{s_type}: #{name}"
  end

  private

  def check_editable_fields
    return if new_record? || !system_tag

    errors.add :name, 'Cannot be changed on a system_tag' if name_changed?
    errors.add :slug, 'Cannot be changed on a system_tag' if slug_changed?
  end
end
