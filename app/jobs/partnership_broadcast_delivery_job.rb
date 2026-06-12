# frozen_string_literal: true

# One job per broadcast recipient — BCC-style privacy and per-recipient
# retry without re-sending to everyone.
class PartnershipBroadcastDeliveryJob < ApplicationJob
  def perform(user, broadcast)
    PartnershipBroadcastMailer.broadcast(user, broadcast).deliver_now
  end
end
