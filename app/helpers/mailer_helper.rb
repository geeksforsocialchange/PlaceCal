# frozen_string_literal: true

module MailerHelper
  def greeting_text(user)
    name = user.full_name.to_s.strip
    name.empty? ? I18n.t('mailers.greeting') : I18n.t('mailers.greeting_with_name', name:)
  end
end
