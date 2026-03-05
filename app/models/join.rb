# frozen_string_literal: true

class Join
  include ActiveModel::Model
  include ActiveModel::Attributes

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
