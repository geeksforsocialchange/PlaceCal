# frozen_string_literal: true

class Views::Mailers::Moderation::HiddenMessage < Views::Mailers::Moderation::Base
  prop :user, User, reader: :private

  def email_content
    div { image_tag(image_url('logo.png'), height: '75') }

    p { "#{greeting_text(user)}," }

    render_hidden_notice
  end
end
