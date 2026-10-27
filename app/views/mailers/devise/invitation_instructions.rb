# frozen_string_literal: true

class Views::Mailers::Devise::InvitationInstructions < Views::Mailers::Base
  prop :resource, User, reader: :private
  prop :token, String, reader: :private

  def email_content
    div { image_tag(image_url('logo.png'), height: '75') }

    p { "#{greeting_text(resource)}," }

    p { t('mailers.invitation_instructions.intro') }

    p { link_to t('mailers.invitation_instructions.link'), accept_invitation_url(resource, invitation_token: token) }

    p { t('mailers.invitation_instructions.ignore') }

    p { t('mailers.invitation_instructions.not_created') }

    p do
      raw t('mailers.invitation_instructions.terms_html',
            terms_link: view_context.link_to(t('mailers.invitation_instructions.terms_link'), terms_of_use_url))
    end

    p { t('mailers.sign_off') }
  end
end
