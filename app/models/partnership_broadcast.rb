# frozen_string_literal: true

# The sent-broadcasts log (#3256 phase 4, from #1440): one row per
# partnership-admin broadcast, recording sender, subject, body and how many
# people it reached (and how many were excluded for lack of consent).
class PartnershipBroadcast < ApplicationRecord
  DAILY_CAP_WINDOW = 24.hours

  # ==== Attributes ====
  attribute :subject,         :string  # NOT NULL
  attribute :body,            :text    # NOT NULL
  attribute :recipient_count, :integer, default: 0 # NOT NULL
  attribute :excluded_count,  :integer, default: 0 # NOT NULL

  # ==== Associations ====
  belongs_to :partnership
  # Optional so the log survives sender account erasure
  belongs_to :sender, class_name: 'User', optional: true

  # ==== Validations ====
  validates :subject, presence: true
  validates :body, presence: true
  validates :sender, presence: true, on: :create
  validate :enforce_daily_cap, on: :create

  scope :recent_first, -> { order(created_at: :desc) }

  private

  # One broadcast per partnership per day, initially
  def enforce_daily_cap
    return if partnership.blank?
    return unless self.class.where(partnership: partnership)
                      .exists?(created_at: DAILY_CAP_WINDOW.ago..)

    errors.add(:base, :daily_cap)
  end
end
