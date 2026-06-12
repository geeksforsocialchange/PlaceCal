# frozen_string_literal: true

# Append-only audit trail of email subscription changes — the record that
# answers "what did this person consent to, when, and how". Scoped to email
# consent only; deliberately not a general activity log (see #2371).
# Rows are written by EmailSubscription.set and can never be updated or
# destroyed.
class EmailSubscriptionEvent < ApplicationRecord
  extend Enumerize

  # ==== Enums / Enumerize ====
  enumerize :source, in: EmailSubscription::SOURCES

  # ==== Attributes ====
  attribute :list_key,       :string  # NOT NULL
  attribute :old_subscribed, :boolean # nullable: nil = no previous record
  attribute :new_subscribed, :boolean # NOT NULL
  # source -- managed by enumerize, attribute declaration skipped # NOT NULL

  # ==== Associations ====
  belongs_to :user
  belongs_to :actor, class_name: 'User', optional: true

  # ==== Validations ====
  validates :list_key, presence: true, inclusion: { in: EmailList.keys }
  validates :new_subscribed, inclusion: { in: [true, false] }
  validates :source, presence: true

  before_destroy { raise ActiveRecord::ReadOnlyRecord }

  def readonly?
    persisted?
  end
end
