# frozen_string_literal: true

# Verify-before-visible invitation (#3256 phase 5, from #2256/#2278): sent
# to a prospective partner's named contact when an organiser adds them (or
# clicks the invite button). Transactional — no list declaration — because
# it's a one-off solicited message, not recurring marketing; the click is
# itself the consent event.
class PartnerVerificationMailer < ApplicationMailer
  # @param partner [Partner]
  # @param email [String]
  # @param invited_by [User]
  def invite(partner, email:, invited_by:)
    props = {
      partner: partner,
      invited_by_name: invited_by.full_name.presence || 'PlaceCal',
      verify_url: partner_verification_url(token: PartnerVerificationsController.token_for(partner))
    }

    mail(to: email, subject: t('partner_verification_mailer.invite.subject', partner: partner.name)) do |format|
      format.html { render Views::Mailers::PartnerVerifications::Invite.new(**props) }
      format.text { render Views::Mailers::PartnerVerifications::InviteText.new(**props) }
    end
  end
end
