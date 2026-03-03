# frozen_string_literal: true

class Views::Mailers::Devise::PasswordChange < Views::Mailers::Base
  prop :resource, User, reader: :private

  def email_content
    p { "#{helpers.greeting_text(resource)}," }

    p { "We're contacting you to notify you that your password has been changed." }
  end
end
