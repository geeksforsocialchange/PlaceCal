# frozen_string_literal: true

class JoinMailer < ApplicationMailer
  # Takes plain arguments rather than a ContactRequest so it can be queued.
  def join_us(attributes:, site_id: nil, demo: false)
    site = Site.find_by(id: site_id) if site_id
    contact_request = ContactRequest.new(attributes.merge(site:, demo:))
    # A queued job has no request Current, and the mail's `t` reads the theme from it.
    Current.set(site:, theme: PlaceCal::Theme.for(site)) do
      # A newline in the name could inject mail headers.
      subject = if site
                  t('join_mailer.join_us.subject_with_site', site: site.name.to_s.delete("\r\n"))
                elsif contact_request.demo
                  t('join_mailer.join_us.subject_demo')
                else
                  t('join_mailer.join_us.subject')
                end

      mail(to: site&.join_recipient || ContactRequest::DEFAULT_RECIPIENT, subject: subject) do |format|
        format.html { render Views::Mailers::Join::JoinUs.new(contact_request: contact_request) }
      end
    end
  end
end
