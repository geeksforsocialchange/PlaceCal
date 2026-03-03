# frozen_string_literal: true

class Views::Mailers::Moderation::HiddenMessage < Views::Mailers::Base
  prop :user, User, reader: :private
  prop :partner, Partner, reader: :private
  prop :reason, String, reader: :private

  def email_content
    div { image_tag(image_url('logo.png'), height: '75') }

    p { "#{greeting_text(user)}," }

    p { "Your partner (#{partner.name}, id: #{partner.id}) has been hidden from PlaceCal for the following reasons:" }

    raw safe(reason.to_s)

    p do
      plain 'Once you have fixed this issue get in touch with '
      a(href: 'mailto:support@placecal.org') { 'support@placecal.org' }
      plain ' so that we can make you public again. If you feel this was in error, or that this action is unreasonable, you can raise a support ticket with PlaceCal here: '
      a(href: 'mailto:support@placecal.org') { 'support@placecal.org' }
      plain '.'
    end
  end
end
