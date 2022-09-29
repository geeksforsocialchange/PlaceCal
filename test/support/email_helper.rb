module EmailHelper
  # get the last email sent by ActionMailer
  #
  # Returns
  #   last email or nil if none sent
  def last_email_delivered
    ActionMailer::Base.deliveries.last
  end

  # extract a link from an email
  #
  # Parameters
  #   email: the email returned by `last_email_delivered`
  #
  # Returns
  #   string of link if found or nil
  def extract_link_from(email)
    body_text = email.body.raw_source

    if body_text.empty?
      html_body = email.parts.find { |p| p.mime_type == 'text/html' }
      return if html_body.nil?

      body_text = html_body.decoded
    end

    body_text =~ %r{<a href="(https?://[^"]*)"} && Regexp.last_match(1)
  end
end
