# frozen_string_literal: true

class Tag < ApplicationRecord
  # -- Includes / Extends --
  extend FriendlyId
  extend Enumerize

  # -- Constants --
  self.table_name = 'tags' # Maybe we can remove this? Tag should automagically railsify to tags right?

  # -- Attributes --
  attribute :description, :text
  attribute :name,        :string
  attribute :slug,        :string
  attribute :system_tag,  :boolean, default: false
  # type -- managed by Rails STI, attribute declaration skipped

  friendly_id :name, use: :slugged

  # -- Associations --
  has_many :tags_users, dependent: :destroy
  has_many :users, through: :tags_users

  has_many :partner_tags, dependent: :destroy
  has_many :partners, through: :partner_tags

  has_many :sites_tag, dependent: :destroy
  has_many :sites, through: :sites_tag

  has_many :article_tags, dependent: :destroy
  has_many :articles, through: :article_tags

  # -- Validations --
  validates :name, :slug, :type, presence: true
  validates :name, :slug, uniqueness: { scope: :type }
  validates :description,
            length: {
              maximum: 200,
              too_long: 'maximum length is 200 characters'
            }
  validates :type,
            inclusion: {
              in: %w[Partnership Facility Category],
              message: 'Type must be one of Category, Facility or Partnership'
            }
  validate :check_editable_fields

  # -- Scopes --
  # TECHDEBT
  # we should look to work this out of the system as we now cover this with a scope on Partnership
  scope :users_tags, lambda { |user|
                       return Tag.all if user.role == 'root' && !user.partnership_admin?

                       partnership_tags = Tag.where(type: 'Partnership', id: user.tags_users.distinct.pluck(:tag_id)).pluck(:id)
                       other_tags = Tag.where("type != 'Partnership'").pluck(:id)

                       Tag.where(id: partnership_tags + other_tags)
                     }

  # -- Instance methods --
  def name_with_type
    s_type = type || 'Tag'
    "#{s_type}: #{name}"
  end

  private

  # -- Private methods --
  def check_editable_fields
    return if new_record? || !system_tag

    errors.add :name, 'Cannot be changed on a system_tag' if name_changed?
    errors.add :slug, 'Cannot be changed on a system_tag' if slug_changed?
  end
end
