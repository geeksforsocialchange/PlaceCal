# frozen_string_literal: true

# app/models/user.rb
class User < ApplicationRecord
  extend Enumerize
  enumerize :role, in: %i[root turf_admin partner_admin guest]
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable, :invitable,
         :omniauthable, omniauth_providers: %i[facebook]

  has_and_belongs_to_many :partners
  has_and_belongs_to_many :turfs
  has_many :sites, foreign_key: :site_admin

  validates_presence_of :email
  validates_uniqueness_of :email

  before_save :update_role

  def full_name
    (first_name || '') + ' ' + (last_name || '')
  end

  def admin_name
    "#{last_name}, #{first_name} <#{email}>"
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
    errors.add(:partner_ids, "can't be blank") if partner_ids.blank?
    errors.add(:role, "can't be blank") if role.blank?

    errors.blank?
  end
end
