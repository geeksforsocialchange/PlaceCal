# frozen_string_literal: true

# The recurring partner digest (#3256 phase 2): one email per user covering
# all their partners. Subscription enforcement and unsubscribe headers come
# from EmailListGuard via the email_list declaration.
class PartnerDigestMailer < ApplicationMailer
  email_list :partner_digest

  # @param user [User]
  # @param digest [PartnerDigest] injectable for previews
  def digest(user, digest: PartnerDigest.new(user))
    props = {
      digest: digest,
      confirm_url: partner_info_confirmation_url(token: PartnerInfoConfirmationsController.token_for(user)),
      preferences_url: email_preferences_url_for(user),
      sign_in_url: new_user_session_url,
      password_reset_url: new_user_password_url
    }

    mail(to: user.email) do |format|
      format.html { render Views::Mailers::PartnerDigest::Digest.new(**props) }
      format.text { render Views::Mailers::PartnerDigest::DigestText.new(**props) }
    end
  end
end
