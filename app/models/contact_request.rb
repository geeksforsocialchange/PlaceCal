# frozen_string_literal: true

class ContactRequest
  include ActiveModel::Model
  include ActiveModel::Attributes

  # Strong-params whitelist shared by the two controllers that receive this
  # form (get-in-touch and the join site's book-a-demo).
  PERMITTED_PARAMS = %i[name email phone job_title job_org area ringback more_info why].freeze
  # Fallback recipient for enquiries that arrive without a site, or from a
  # site with no contact_email of its own (#3368, D13).
  DEFAULT_RECIPIENT = 'support@placecal.org'

  attribute :name, :string
  attribute :email, :string
  attribute :phone, :string
  attribute :job_title, :string
  attribute :job_org, :string
  attribute :area, :string
  attribute :ringback, :boolean
  attribute :more_info, :boolean
  attribute :why, :string

  # The site the enquiry was submitted from, if any. Not a form field: the
  # controller sets it from current_site, and the directory leaves it nil.
  attr_accessor :site

  validates :name, :email, :why, presence: true

  def submit
    valid? && JoinMailer.join_us(self).deliver
  end
end
