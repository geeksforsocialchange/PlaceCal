# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'support@placecal.org'
  layout 'mailer'
end
