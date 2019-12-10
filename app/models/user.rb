# frozen_string_literal: true

# app/models/user.rb
class User < ApplicationRecord
  include Validation
  extend Enumerize

  # Non-root roles are updated after save based on assignments
  enumerize :role,
            in: %i[root turf_admin partner_admin citizen],
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
  # # TODO: Rename to 'interests' on DB level
  # has_many :turfs_users, dependent: :destroy
  # has_many :turfs, through: :turfs_users
  has_and_belongs_to_many :partners
  has_and_belongs_to_many :turfs
  has_many :sites, foreign_key: :site_admin

  has_many :neighbourhoods_users, dependent: :destroy
  has_many :neighbourhoods, through: :neighbourhoods_users

  validates :email,
            presence: true,
            uniqueness: true,
            format: { with: EMAIL_REGEX, message: 'invalid email address' }

  before_save :update_role

  mount_uploader :avatar, AvatarUploader

  # General use throughout the site
  def full_name
    if first_name.present? && last_name.present?
      "#{first_name} #{last_name}"
    elsif first_name.present?
      first_name
    elsif last_name.present?
      last_name
    else
      false
    end
  end

  # Shows in admin interfaces
  def admin_name
    name = if first_name.present? && last_name.present?
             "#{last_name.upcase}, #{first_name}"
           elsif first_name.present?
             first_name
           elsif last_name.present?
             last_name.upcase
           end
    "#{name} <#{email}>"
  end

  # Protects from unnecessary database queries
  def update_role
    return if role == 'root'

    self.role =
      if turfs.any?
        'turf_admin'
      elsif partners.any?
        'partner_admin'
      end
  end

  def valid_for_invite
    errors.add(:email, "can't be blank") if email.blank?
    errors.add(:first_name, "can't be blank") if first_name.blank?
    errors.add(:last_name, "can't be blank") if last_name.blank?
    errors.add(:role, "can't be blank") if role.blank?

    errors.blank?
  end

  def has_facebook_keys?
    facebook_app_id.present? && facebook_app_secret.present?
  end
end
