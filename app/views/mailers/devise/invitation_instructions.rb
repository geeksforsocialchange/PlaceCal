# frozen_string_literal: true

class Views::Mailers::Devise::InvitationInstructions < Views::Mailers::Base
  prop :resource, User, reader: :private
  prop :token, String, reader: :private

  def email_content
    div { image_tag(image_url('logo.png'), height: '75') }

    p { "#{helpers.greeting_text(resource)}," }

    p { "You've been invited to join PlaceCal! You can accept this invite by clicking the link below." }

    p { link_to 'Join PlaceCal', helpers.accept_invitation_url(resource, invitation_token: token) }

    p { "If you don't want to accept the invitation, please ignore this email." }

    p { "Your account won't be created until you access the link above and set your password." }

    p do
      plain 'By accepting the invitation and finalising your PlaceCal account you hereby agree to the PlaceCal '
      link_to 'Terms of Use', helpers.terms_of_use_url
      plain '.'
    end

    p { '- The PlaceCal Team' }
  end
end
