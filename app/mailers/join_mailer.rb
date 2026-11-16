# frozen_string_literal: true

class JoinMailer < ApplicationMailer
  # Takes plain arguments rather than a ContactRequest so it can be queued.
  def join_us(attributes:, site_id: nil, demo: false)
    site = Site.find_by(id: site_id) if site_id
    contact_request = ContactRequest.new(attributes.merge(site:, demo:))
    # A queued job has no request Current, and the mail's `t` reads the theme from it.
    Current.set(site:, theme: PlaceCal::Theme.for(site)) do
      mail(to: site&.join_recipient || ContactRequest::DEFAULT_RECIPIENT,
           subject: subject_for(contact_request),
           reply_to: enquirer_address(contact_request)) do |format|
        format.html { render Views::Mailers::Join::JoinUs.new(contact_request:) }
      end
    end
  end

  private

  def subject_for(contact_request)
    site = contact_request.site
    # A newline in the name could inject mail headers.
    return t('join_mailer.join_us.subject_with_site', site: site.name.to_s.delete("\r\n")) if site
    return t('join_mailer.join_us.subject_demo') if contact_request.demo

    t('join_mailer.join_us.subject')
  end

  # Left off unless the email is a plain address: the form only checks it is present.
  def enquirer_address(contact_request)
    email = contact_request.email.to_s.strip
    return unless email.match?(URI::MailTo::EMAIL_REGEXP)

    email_address_with_name(email, contact_request.name.to_s.delete("\r\n"))
  end
end
