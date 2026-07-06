# frozen_string_literal: true

# One job per broadcast recipient — BCC-style privacy and per-recipient
# retry without re-sending to everyone.
class PartnershipBroadcastDeliveryJob < ApplicationJob
  # Recipient or broadcast erased between enqueue and send — nothing to do
  discard_on ActiveJob::DeserializationError

  def perform(user, broadcast)
    PartnershipBroadcastMailer.broadcast(user, broadcast).deliver_now
  end
end
