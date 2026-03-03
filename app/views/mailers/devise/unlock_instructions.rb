# frozen_string_literal: true

class Views::Mailers::Devise::UnlockInstructions < Views::Mailers::Base
  prop :resource, User, reader: :private
  prop :token, String, reader: :private

  def email_content
    p { "#{helpers.greeting_text(resource)}," }

    p { 'Your account has been locked due to an excessive number of unsuccessful sign in attempts.' }

    p { 'Click the link below to unlock your account:' }

    p { link_to 'Unlock my account', helpers.unlock_url(resource, unlock_token: token) }
  end
end
