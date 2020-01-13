# frozen_string_literal: true

# app/models/user.rb
class User < ApplicationRecord
  include Validation
  extend Enumerize

  # Site-wide roles
  enumerize :role,
            in: %i[root citizen]

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
  # # TODO: Rename to 'tags' on DB level
  # has_many :tags_users, dependent: :destroy
  # has_many :tags, through: :tags_users

  has_and_belongs_to_many :partners
  has_and_belongs_to_many :tags
  has_many :sites, foreign_key: :site_admin

  has_many :neighbourhoods_users, dependent: :destroy
  has_many :neighbourhoods, through: :neighbourhoods_users

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

  def neighbourhood_admin?
    neighbourhoods.any?
  end

  def partner_admin?
    partners.any?
  end

  def tag_admin?
    tags.any?
  end

  def site_admin?
    Site.where(site_admin: self).any?
  end

  def has_facebook_keys?
    facebook_app_id.present? && facebook_app_secret.present?
  end
end
