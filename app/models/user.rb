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
         :validatable, :invitable,
         :omniauthable, omniauth_providers: %i[facebook]

  crypt_keeper :facebook_app_id,
               :facebook_app_secret,
               encryptor: :active_support,
               key: Rails.application.secrets.crypt_keeper_key,
               salt: Rails.application.secrets.crypt_keeper_salt

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

  mount_uploader :avatar, AvatarUploader

  # General use throughout the site
  def full_name
    [first_name, last_name].reject(&:blank?).join(' ')
  end

  # Shows in admin interfaces
  def admin_name
    name = [last_name&.upcase, first_name].reject(&:blank?).join(', ')

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

  def can_alter_neighbourhood?(neighbourhood)
    owned_neighbourhoods.include? neighbourhood
  end

  def neighbourhood_admin?
    neighbourhoods.any?
  end

  def partner_admin?
    partners.any?
  end

  def tag_admin?
    tags.any?
  end

  def admin_roles
    types = []

    types << 'root' if root?
    types << 'editor' if editor?
    types << 'neighbourhood_admin' if neighbourhood_admin?
    types << 'partner_admin' if partner_admin?
    types << 'tag_admin' if tag_admin?

    types.join(', ')
  end

  def site_admin?
    Site.where(site_admin: self).any?
  end

  def has_facebook_keys?
    facebook_app_id.present? && facebook_app_secret.present?
  end

  def self.role_label(value)
    case value.second
    when 'root'
      '<strong>Root</strong>: Can do everything'.html_safe
    when 'editor'
      '<strong>Editor</strong>: Can edit news articles'.html_safe
    when 'citizen'
      '<strong>Citizen</strong>: ' \
      'Can only edit entities listed on this page'.html_safe
    else
      value
    end
  end

  def assigned_to_postcode?(postcode)
    return true unless neighbourhood_admin?

    res = Geocoder.search(postcode).first&.data

    return false unless res

    neighbourhood = Neighbourhood.find_by(unit: 'ward',
                                          unit_code_key: 'WD19CD',
                                          unit_code_value: res.dig('codes', 'admin_ward'))
    owned_neighbourhood_ids.include?(neighbourhood&.id)
  end

  protected

  def password_required?
    return false if skip_password_validation

    super
  end
end
