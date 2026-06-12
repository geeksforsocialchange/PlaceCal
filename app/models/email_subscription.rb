# frozen_string_literal: true

# One row per (user, list) recording an explicit subscription decision.
# `subscribed` means the same thing regardless of list polarity; absence of
# a row falls back to the list's default policy in the EmailList registry.
# All writes go through .set so the append-only audit trail
# (EmailSubscriptionEvent) can never be skipped.
class EmailSubscription < ApplicationRecord
  extend Enumerize

  SOURCES = %w[profile_page unsubscribe_link admin legacy_onboarding].freeze

  # ==== Enums / Enumerize ====
  enumerize :source, in: SOURCES

  # ==== Attributes ====
  attribute :list_key,   :string  # NOT NULL
  attribute :subscribed, :boolean # NOT NULL
  # source -- managed by enumerize, attribute declaration skipped # NOT NULL

  # ==== Associations ====
  belongs_to :user

  # ==== Validations ====
  validates :list_key,
            presence: true,
            uniqueness: { scope: :user_id },
            inclusion: { in: EmailList.keys }
  validates :subscribed, inclusion: { in: [true, false] }
  validates :source, presence: true

  # @param user [User]
  # @param list_key [String, Symbol]
  # @return [Boolean] effective state, combining row state with the
  #   registry default when no row exists
  def self.subscribed?(user, list_key)
    list = EmailList.find!(list_key)
    row = find_by(user: user, list_key: list.key)
    row ? row.subscribed : list.default_subscribed?
  end

  # The single write path: upserts the row and appends an audit event.
  # A no-op when the explicit recorded state is unchanged.
  #
  # @param user [User]
  # @param list_key [String, Symbol]
  # @param subscribed [Boolean]
  # @param source [String, Symbol] one of SOURCES
  # @param actor [User, nil] who made the change, when not the user themselves
  # @return [EmailSubscription]
  def self.set(user, list_key, subscribed, source:, actor: nil)
    list = EmailList.find!(list_key)

    transaction do
      row = find_or_initialize_by(user: user, list_key: list.key.to_s)
      old_subscribed = row.persisted? ? row.subscribed : nil
      next row if old_subscribed == subscribed

      row.update!(subscribed: subscribed, source: source)
      EmailSubscriptionEvent.create!(
        user: user,
        list_key: list.key.to_s,
        old_subscribed: old_subscribed,
        new_subscribed: subscribed,
        source: source,
        actor: actor
      )
      row
    end
  end
end
