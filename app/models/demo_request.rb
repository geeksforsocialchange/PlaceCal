# frozen_string_literal: true

# "Book a demo" enquiry from the join marketing site (join.placecal.org).
# Not persisted — like JoinRequest, it's a form object that delivers a mail.
class DemoRequest
  include ActiveModel::Model
  include ActiveModel::Attributes

  # Audience keys a demo enquirer can pick from, matching the "Who it's for"
  # pages on the join site (and the old audience pages they replace).
  AUDIENCES = %w[
    community_groups
    metropolitan_areas
    housing_providers
    social_prescribers
    vcses
    culture_tourism
  ].freeze

  attribute :name, :string
  attribute :email, :string
  attribute :organisation, :string
  attribute :audience, :string
  attribute :message, :string

  validates :name, :email, presence: true
  validates :audience, inclusion: { in: AUDIENCES }, allow_blank: true

  def submit
    valid? && JoinMailer.demo_request(self).deliver
  end
end
