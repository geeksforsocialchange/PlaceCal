# frozen_string_literal: true

module MailerHelper
  def greeting_text(user)
    ['Hello', user.full_name].join(' ').strip
  end
end
