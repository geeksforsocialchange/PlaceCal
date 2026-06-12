# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  include EmailListGuard

  default from: 'no-reply@placecal.org'
  layout false
  helper MailerHelper
end
