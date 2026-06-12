# frozen_string_literal: true

# Append-only consent provenance for partner listings (#3256 phase 5): how
# and where we got permission to publish this organisation. Same honest-
# record philosophy as the email_subscription_events audit trail.
class PartnerConsent < ApplicationRecord
  extend Enumerize

  BASES = %w[asked_in_person they_contacted_us public_listing verified_by_email other].freeze

  # ==== Enums / Enumerize ====
  enumerize :basis, in: BASES

  # ==== Associations ====
  belongs_to :partner
  belongs_to :recorded_by, class_name: 'User', optional: true

  # ==== Validations ====
  validates :basis, presence: true

  before_destroy { raise ActiveRecord::ReadOnlyRecord }

  def readonly?
    persisted?
  end
end
