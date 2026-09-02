# frozen_string_literal: true

class Join
  include ActiveModel::Model
  include ActiveModel::Attributes

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
