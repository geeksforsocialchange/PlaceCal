# frozen_string_literal: true

class Views::Mailers::Devise::ConfirmationInstructions < Views::Mailers::Base
  prop :resource, User, reader: :private
  prop :token, String, reader: :private

  def email_content
    p { "#{helpers.greeting_text(resource)}," }

    p { 'You can confirm your account email through the link below:' }

    p { link_to 'Confirm my account', helpers.confirmation_url(resource, confirmation_token: token) }
  end
end
