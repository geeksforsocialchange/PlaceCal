# frozen_string_literal: true

class Views::Mailers::Devise::ResetPasswordInstructions < Views::Mailers::Base
  prop :resource, User, reader: :private
  prop :token, String, reader: :private

  def email_content
    p { "#{greeting_text(resource)}," }

    p { t('mailers.reset_password_instructions.intro') }

    p { link_to t('mailers.reset_password_instructions.link'), edit_password_url(resource, reset_password_token: token) }

    p { t('mailers.reset_password_instructions.ignore') }
    p { t('mailers.reset_password_instructions.unchanged') }
  end
end
