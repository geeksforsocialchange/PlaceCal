# frozen_string_literal: true

class Views::Mailers::Devise::InvitationInstructionsText < Views::TextBase
  prop :resource, User, reader: :private
  prop :token, String, reader: :private

  def text_content
    <<~TEXT
      #{helpers.greeting_text(resource)},

      You've been invited to join PlaceCal! You can accept this invite by copying the link below into your browser.

      #{helpers.accept_invitation_url(resource, invitation_token: token)}

      If you don't want to accept the invitation, please ignore this email.

      Your account won't be created until you access the link above and set your password.

      By accepting the invitation and finalising your PlaceCal account you hereby agree to the PlaceCal 'Terms of Use' policy as laid out here: #{helpers.terms_of_use_url}.

      - The PlaceCal Team
    TEXT
  end
end
