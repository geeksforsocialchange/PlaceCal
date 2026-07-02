# frozen_string_literal: true

class ContactRequest
  include ActiveModel::Model
  include ActiveModel::Attributes

  # Strong-params whitelist shared by the two controllers that receive this
  # form (get-in-touch and the join site's book-a-demo).
  PERMITTED_PARAMS = %i[name email phone job_title job_org area ringback more_info why].freeze

  attribute :name, :string
  attribute :email, :string
  attribute :phone, :string
  attribute :job_title, :string
  attribute :job_org, :string
  attribute :area, :string
  attribute :ringback, :boolean
  attribute :more_info, :boolean
  attribute :why, :string

  validates :name, :email, :why, presence: true

  def submit
    valid? && JoinMailer.join_us(self).deliver
  end
end
