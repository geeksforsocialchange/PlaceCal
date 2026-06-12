# frozen_string_literal: true

# Sends one user's partner digest and stamps partner_digest_last_sent_at.
# Idempotent: re-checks due-ness so a double enqueue (e.g. scheduler retry)
# can't double-send, and the timestamp is only written when the mail was
# actually delivered — a user suppressed by the subscription guard keeps
# their first-contact state for if they ever resubscribe.
class PartnerDigestDeliveryJob < ApplicationJob
  def perform(user)
    return unless user.partners.any?
    return unless due?(user)

    mail = PartnerDigestMailer.digest(user)
    mail.deliver_now

    user.update!(partner_digest_last_sent_at: Time.current) if mail.perform_deliveries
  end

  private

  def due?(user)
    last_sent = user.partner_digest_last_sent_at
    last_sent.nil? || last_sent <= RecurringPartnerDigestJob.send_interval.ago
  end
end
