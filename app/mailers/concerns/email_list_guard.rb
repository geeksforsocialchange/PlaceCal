# frozen_string_literal: true

# Central subscription enforcement for list email (ADR 0015). A mailer
# declares its list with `email_list :partner_digest`; every message it
# builds is then checked against EmailSubscription and silently suppressed
# for unsubscribed (or unknown) recipients, and carries the one-click
# unsubscribe headers Gmail/Yahoo require (RFC 8058).
#
# Mailers that declare no list are transactional (password resets,
# invitations…) and always send. The check lives here, not at call sites,
# so a forgotten guard can't email an unsubscribed user.
module EmailListGuard
  extend ActiveSupport::Concern

  included do
    class_attribute :email_list_key, instance_writer: false
    after_action :enforce_email_subscription
  end

  class_methods do
    # @param key [Symbol, String] a key registered in EmailList
    def email_list(key)
      self.email_list_key = EmailList.find!(key).key
    end
  end

  # @param user [User]
  # @return [String] signed no-login preferences URL for email footers
  def email_preferences_url_for(user)
    email_preferences_url(token: EmailPreferencesController.token_for(user))
  end

  private

  def enforce_email_subscription
    return if email_list_key.blank?

    user = email_list_recipient
    if user.nil? || !EmailSubscription.subscribed?(user, email_list_key)
      message.perform_deliveries = false
      return
    end

    token = EmailPreferencesController.token_for(user)
    message.headers(
      'List-Unsubscribe' => "<#{email_preferences_unsubscribe_url(token: token, list: email_list_key)}>",
      'List-Unsubscribe-Post' => 'List-Unsubscribe=One-Click'
    )
  end

  # List email goes to account holders, so the recipient address identifies
  # the user. Unknown addresses are suppressed: no account means no consent
  # state to check. Override in a mailer if its recipient resolution differs.
  #
  # @return [User, nil]
  def email_list_recipient
    User.find_by(email: Array(message.to).first)
  end
end
