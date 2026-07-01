# frozen_string_literal: true

# Partnership-admin broadcasts (#3256 phase 4). Recipients are pre-filtered
# through the partnership_updates opt-in by BroadcastRecipientsQuery, with
# EmailListGuard as the structural backstop. BCC-style privacy: one message
# per recipient, the list is never exposed. Replies go to the sender.
class PartnershipBroadcastMailer < ApplicationMailer
  email_list :partnership_updates

  # @param user [User]
  # @param broadcast [PartnershipBroadcast]
  def broadcast(user, broadcast)
    props = {
      broadcast: broadcast,
      preferences_url: email_preferences_url_for(user)
    }

    mail(to: user.email,
         subject: broadcast.subject,
         reply_to: broadcast.sender&.email) do |format|
      format.html { render Views::Mailers::PartnershipBroadcasts::Broadcast.new(**props) }
      format.text { render Views::Mailers::PartnershipBroadcasts::BroadcastText.new(**props) }
    end
  end
end
