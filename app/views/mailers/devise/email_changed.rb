# frozen_string_literal: true

class Views::Mailers::Devise::EmailChanged < Views::Mailers::Base
  prop :resource, User, reader: :private

  def email_content
    p { "#{helpers.greeting_text(resource)}," }

    if resource.try(:unconfirmed_email?)
      p { "We're contacting you to notify you that your email is being changed to #{resource.unconfirmed_email}." }
    else
      p { "We're contacting you to notify you that your email has been changed to #{resource.email}." }
    end
  end
end
