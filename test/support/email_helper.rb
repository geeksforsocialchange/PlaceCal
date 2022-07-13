module EmailHelper

  def last_email_delivered
    ActionMailer::Base.deliveries.last
  end

  def extract_link_from(email)
    body_text = email.body.raw_source
    body_text =~ /<a href="(https?:\/\/[^"]*)"/ && $1
  end
end
