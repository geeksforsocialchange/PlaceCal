# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'no-reply@placecal.org'
  layout 'mailer'
  helper MailerHelper
end
