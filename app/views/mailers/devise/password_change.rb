# frozen_string_literal: true

class Views::Mailers::Devise::PasswordChange < Views::Mailers::Base
  prop :resource, User, reader: :private

  def email_content
    p { "#{greeting_text(resource)}," }

    p { t('mailers.password_change.notice') }
  end
end
