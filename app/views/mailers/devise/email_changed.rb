# frozen_string_literal: true

class Views::Mailers::Devise::EmailChanged < Views::Mailers::Base
  prop :resource, User, reader: :private

  def email_content
    p { "#{greeting_text(resource)}," }

    if resource.try(:unconfirmed_email?)
      p { t('mailers.email_changed.changing', email: resource.unconfirmed_email) }
    else
      p { t('mailers.email_changed.changed', email: resource.email) }
    end
  end
end
