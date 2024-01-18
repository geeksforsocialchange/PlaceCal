# frozen_string_literal: true

# app/models/user.rb
class User < ApplicationRecord
  include Validation
  extend Enumerize

  attr_accessor :skip_password_validation, :current_password

  # Site-wide roles
  enumerize :role,
            in: %i[root editor citizen],
            default: :citizen

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable
  devise :database_authenticatable, :recoverable, :rememberable, :trackable,
         :validatable, :invitable

  # TODO: set up join models properly
  # has_many :partners_users, dependent: :destroy
  # has_many :partners, through: :partners_users

  has_and_belongs_to_many :partners
  has_many :sites, foreign_key: :site_admin

  has_many :neighbourhoods_users, dependent: :destroy
  has_many :neighbourhoods, through: :neighbourhoods_users

  has_many :tags_users, dependent: :destroy
  has_many :tags, through: :tags_users

  validates :email,
            presence: true,
            uniqueness: true,
            format: { with: EMAIL_REGEX, message: 'invalid email address' }
  validates :role, presence: true

  validate :validate_tags_are_partnerships

  mount_uploader :avatar, AvatarUploader

  # General use throughout the site
  def full_name
    [first_name, last_name].compact_blank.join(' ')
  end

  # Shows in admin interfaces
  def admin_name
    name = [last_name&.upcase, first_name].compact_blank.join(', ')

    "#{name} <#{email}>".strip
  end

  alias to_s admin_name

  # Admin level checks
  def root?
    role == :root
  end

  def citizen?
    role == :citizen
  end

  def editor?
    role == :editor
  end

  def owned_neighbourhoods
    neighbourhoods.collect(&:subtree).flatten
  end

  def owned_neighbourhood_ids
    owned_neighbourhoods.collect(&:id)
  end

  def admin_for_partner?(partner_id)
    partners.pluck(:id).include? partner_id
  end

  def partnership_admin_for_partner?(partner_id)
    partner_id.present? &&
      partner_in_neighbourhood_scope?(partner_id) &&
      partner_in_partnership_scope?(partner_id)
  end

  def neighbourhood_admin_for_partner?(partner_id)
    partner_id.present? &&
      !partnership_admin? &&
      partner_in_neighbourhood_scope?(partner_id)
  end

  def only_neighbourhood_admin_for_partner?(partner_id)
    neighbourhood_admin? &&
      Set.new(owned_neighbourhood_ids).superset?(
        Set.new(
          Partner.find_by(id: partner_id)&.owned_neighbourhood_ids
        )
      )
  end

  def can_view_neighbourhood_by_id?(neighbourhood_id)
    root? || (
      neighbourhood_admin? &&
      owned_neighbourhood_ids.include?(neighbourhood_id)
    )
  end

  def can_edit_partners_neighbourhood_by_id?(neighbourhood_id, partner_id = nil)
    root? || (
      neighbourhood_admin? &&
      owned_neighbourhood_ids.include?(neighbourhood_id)
    ) || admin_for_partner?(partner_id)
  end

  def neighbourhood_admin?
    neighbourhoods.any?
  end

  def partner_admin?
    partners.any?
  end

  def partnership_admin?
    tags.any? { |tag| tag[:type] == 'Partnership' }
  end

  def admin_roles
    types = []

    types << 'root' if root?
    types << 'editor' if editor?
    types << 'neighbourhood_admin' if neighbourhood_admin?
    types << 'partner_admin' if partner_admin?
    types << 'partnership_admin' if partnership_admin?
    types << 'site_admin' if site_admin?

    types.join(', ')
  end

  def site_admin?
    Site.where(site_admin: self).any?
  end

  def assigned_to_postcode?(postcode)
    return true if root?

    return true unless neighbourhood_admin?

    res = Geocoder.search(postcode).first&.data
    return false unless res

    neighbourhood = Neighbourhood.find_from_postcodesio_response(res)
    owned_neighbourhood_ids.include?(neighbourhood&.id)
  end

  protected

  def partner_in_neighbourhood_scope?(partner_id)
    neighbourhood_admin? &&
      (
        owned_neighbourhood_ids & (
          Partner.find_by(id: partner_id).owned_neighbourhood_ids
        )
      ).any?
  end

  def partner_in_partnership_scope?(partner_id)
    partnership_admin? &&
      (
        tags.map(&:id) &
        Partner.find_by(id: partner_id).partnerships.map(&:id)
      ).any?
  end

  def validate_tags_are_partnerships
    return true if tags.all?(Partnership)

    errors.add(:tags, 'Can only be of type Partnership')
  end

  def password_required?
    return false if skip_password_validation

    super
  end
end
