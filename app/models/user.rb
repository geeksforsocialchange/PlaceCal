# frozen_string_literal: true

class User < ApplicationRecord
  # -- Includes / Extends --
  include Validation
  extend Enumerize

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable
  devise :database_authenticatable, :recoverable, :rememberable, :trackable,
         :validatable, :invitable

  # -- Enums / Enumerize --
  # Site-wide roles
  # - root: Can do everything
  # - national_admin: Can manage all partners unless restricted to partnerships
  # - editor: Can edit all news articles
  # - citizen: Can only edit assigned entities
  enumerize :role,
            in: %i[root national_admin editor citizen],
            default: :citizen
  # role -- managed by enumerize, attribute declaration skipped

  # -- Attributes --
  # Columns marked (nullable) have no NOT NULL constraint in the DB.
  attribute :access_token,             :string                  # nullable
  attribute :access_token_expires_at,  :string                  # nullable
  # avatar -- managed by CarrierWave, attribute declaration skipped
  attribute :current_password,         :string                  # virtual, used by password change forms
  # Devise columns (encrypted_password, reset_password_token, reset_password_sent_at,
  #   remember_created_at, sign_in_count, current_sign_in_at, last_sign_in_at,
  #   current_sign_in_ip, last_sign_in_ip, invitation_token, invitation_created_at,
  #   invitation_sent_at, invitation_accepted_at, invitation_limit, invited_by_type,
  #   invited_by_id) -- managed by Devise, attribute declarations skipped
  attribute :email,                    :string, default: ''     # NOT NULL
  attribute :first_name,               :string                  # nullable
  attribute :last_name,                :string                  # nullable
  attribute :phone,                    :string                  # nullable
  # role -- managed by enumerize, attribute declaration skipped  # NOT NULL
  attribute :skip_password_validation, :boolean, default: false # virtual, used by Devise password_required?

  auto_strip_attributes :first_name, :last_name, :email, :phone

  # -- Associations --
  # TODO: set up join models properly
  # has_many :partners_users, dependent: :destroy
  # has_many :partners, through: :partners_users

  has_and_belongs_to_many :partners
  has_many :sites, foreign_key: :site_admin_id, inverse_of: :site_admin, dependent: :nullify
  has_many :articles, foreign_key: :author_id, inverse_of: :author, dependent: :nullify

  has_many :neighbourhoods_users, dependent: :destroy
  has_many :neighbourhoods, through: :neighbourhoods_users
  accepts_nested_attributes_for :neighbourhoods_users, allow_destroy: true, reject_if: :all_blank

  has_many :tags_users, dependent: :destroy
  has_many :tags, through: :tags_users
  has_many :partnerships, -> { where(type: 'Partnership') }, through: :tags_users, source: :tag

  # -- Uploaders --
  mount_uploader :avatar, AvatarUploader

  # -- Validations --
  validates :email,
            presence: true,
            uniqueness: true,
            format: { with: EMAIL_REGEX, message: 'invalid email address' }
  validates :role, presence: true

  validate :validate_tags_are_partnerships

  # -- Instance methods --

  # @return [String] "Firstname Lastname" or empty string
  def full_name
    [first_name, last_name].compact_blank.join(' ')
  end

  # @return [String] "LASTNAME, Firstname <email>" for admin listings
  def admin_name
    name = [last_name&.upcase, first_name].compact_blank.join(', ')

    "#{name} <#{email}>".strip
  end

  # @return [String] "Firstname Lastname (email)"
  def display_name
    name = full_name.presence || email.split('@').first
    "#{name} (#{email})"
  end

  alias to_s admin_name
  alias name admin_name

  # @return [Boolean]
  def root?
    role == :root
  end

  # @return [Boolean]
  def citizen?
    role == :citizen
  end

  # @return [Boolean]
  def editor?
    role == :editor
  end

  # @return [Boolean]
  def national_admin?
    role == :national_admin
  end

  # @return [Array<Neighbourhood>] all neighbourhoods in this user's subtrees
  def owned_neighbourhoods
    if national_admin?
      Neighbourhood.all.to_a
    else
      neighbourhoods.collect(&:subtree).flatten
    end
  end

  # @return [Array<Integer>] all neighbourhood IDs in this user's subtrees
  def owned_neighbourhood_ids
    if national_admin?
      Neighbourhood.pluck(:id)
    else
      owned_neighbourhoods.collect(&:id)
    end
  end

  # @param partner_id [Integer]
  # @return [Boolean] whether user is directly assigned to this partner
  def admin_for_partner?(partner_id)
    partners.pluck(:id).include? partner_id
  end

  # @param partner_id [Integer]
  # @return [Boolean] whether user admins this partner via neighbourhood + partnership scope
  def partnership_admin_for_partner?(partner_id)
    partner_id.present? &&
      partner_in_neighbourhood_scope?(partner_id) &&
      partner_in_partnership_scope?(partner_id)
  end

  # @param partner_id [Integer]
  # @return [Boolean] whether user admins this partner via neighbourhood scope only
  def neighbourhood_admin_for_partner?(partner_id)
    partner_id.present? &&
      !partnership_admin? &&
      partner_in_neighbourhood_scope?(partner_id)
  end

  # @param partner_id [Integer]
  # @return [Boolean] whether user's neighbourhoods fully cover the partner's
  def only_neighbourhood_admin_for_partner?(partner_id)
    (neighbourhood_admin? || partnership_admin?) &&
      Set.new(owned_neighbourhood_ids).superset?(
        Set.new(
          Partner.find_by(id: partner_id)&.owned_neighbourhood_ids
        )
      )
  end

  # @param partner_id [Integer]
  # @return [Boolean] whether user's neighbourhoods and partnerships fully cover the partner's
  def only_partnership_admin_for_partner?(partner_id)
    return unless partnership_admin?

    partner = Partner.find(partner_id)

    user_neighbourhoods = owned_neighbourhood_ids
    user_tags = tags.pluck(:id)

    neighbourhoods_a = Set.new(user_neighbourhoods)
    neighbourhoods_b = Set.new(partner.owned_neighbourhood_ids)
    return false unless neighbourhoods_a.superset?(neighbourhoods_b)

    tags_a = Set.new(user_tags)
    tags_b = Set.new(partner.partnerships.pluck(:id))
    return false unless tags_a.superset?(tags_b)

    true
  end

  # @param neighbourhood_id [Integer]
  # @return [Boolean]
  def can_view_neighbourhood_by_id?(neighbourhood_id)
    root? || (
      neighbourhood_admin? &&
      owned_neighbourhood_ids.include?(neighbourhood_id)
    )
  end

  # @param neighbourhood_id [Integer]
  # @param partner_id [Integer, nil]
  # @return [Boolean]
  def can_edit_partners_neighbourhood_by_id?(neighbourhood_id, partner_id = nil)
    root? || (
      neighbourhood_admin? &&
      owned_neighbourhood_ids.include?(neighbourhood_id)
    ) || admin_for_partner?(partner_id)
  end

  # @return [Boolean] whether user has any neighbourhood assignments
  def neighbourhood_admin?
    national_admin? || neighbourhoods.any?
  end

  # @return [Boolean] whether user is directly assigned to any partners
  def partner_admin?
    partners.any?
  end

  # @return [Boolean] whether user has any Partnership tags
  def partnership_admin?
    tags.any? { |tag| tag[:type] == 'Partnership' }
  end

  # @return [String] comma-separated list of active admin role names
  def admin_roles
    types = []

    types << 'root' if root?
    types << 'national_admin' if national_admin?
    types << 'editor' if editor?
    types << 'neighbourhood_admin' if neighbourhood_admin? && !national_admin?
    types << 'partner_admin' if partner_admin?
    types << 'partnership_admin' if partnership_admin?
    types << 'site_admin' if site_admin?

    types.join(', ')
  end

  # @return [Boolean] whether user is a site admin for any site
  def site_admin?
    Site.where(site_admin: self).any?
  end

  # @param postcode [String] UK postcode to check
  # @return [Boolean] whether the postcode falls within the user's neighbourhoods
  def assigned_to_postcode?(postcode)
    return true if root?

    return true unless neighbourhood_admin?

    res = Geocoder.search(postcode).first&.data
    return false unless res

    neighbourhood = Neighbourhood.find_from_postcodesio_response(res)
    owned_neighbourhood_ids.include?(neighbourhood&.id)
  end

  protected

  # -- Protected methods --

  # @param partner_id [Integer]
  # @return [Boolean] whether partner's neighbourhoods overlap with user's
  def partner_in_neighbourhood_scope?(partner_id)
    neighbourhood_admin? &&
      (
        owned_neighbourhood_ids &
          Partner.find_by(id: partner_id).owned_neighbourhood_ids

      ).any?
  end

  # @param partner_id [Integer]
  # @return [Boolean] whether partner's partnerships overlap with user's tags
  def partner_in_partnership_scope?(partner_id)
    partnership_admin? &&
      (
        tags.map(&:id) &
        Partner.find_by(id: partner_id).partnerships.map(&:id)
      ).any?
  end

  # @return [Boolean]
  def validate_tags_are_partnerships
    return true if tags.all?(Partnership)

    errors.add(:tags, 'Can only be of type Partnership')
  end

  # @return [Boolean]
  def password_required?
    return false if skip_password_validation

    super
  end
end
