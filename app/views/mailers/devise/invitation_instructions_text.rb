# frozen_string_literal: true

class Views::Mailers::Devise::InvitationInstructionsText < Views::TextBase
  register_value_helper :greeting_text
  register_value_helper :accept_invitation_url

  prop :resource, User, reader: :private
  prop :token, String, reader: :private

  def text_content
    <<~TEXT
      #{greeting_text(resource)},

      #{t('mailers.invitation_instructions.intro_text')}

      #{accept_invitation_url(resource, invitation_token: token)}

      #{t('mailers.invitation_instructions.ignore')}

      #{t('mailers.invitation_instructions.not_created')}

      #{t('mailers.invitation_instructions.terms_text', url: terms_of_use_url)}

      #{t('mailers.sign_off')}
    TEXT
  end
end
