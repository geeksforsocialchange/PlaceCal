class ApplicationMailer < ActionMailer::Base
  default from: "no-reply@placecal.org"
  layout "mailer"
end
