# frozen_string_literal: true

class JoinMailer < ApplicationMailer
  # Takes plain arguments rather than a ContactRequest so it can be queued.
  def join_us(attributes:, site_id: nil, demo: false)
    site = Site.find_by(id: site_id) if site_id
    contact_request = ContactRequest.new(attributes.merge('site' => site, 'demo' => demo))
    # Mailer views inherit Views::Base, so their `t` resolves against
    # Current.theme. Current is request-scoped and is already reset by the time
    # a queued job runs, so set it here from the enquiry's own site: the copy must
    # not depend on whether the mail was delivered in the request, from a job,
    # or from a console.
    #
    # Current.set rather than assignment, so a deliver_now inside a request, or
    # a rake task looping over deliveries, gets its own Current back afterwards
    # instead of inheriting this enquiry's site for everything that follows.
    Current.set(site: site, theme: PlaceCal::Theme.for(site)) do
      # A newline in the interpolated name would let it inject extra mail
      # headers, so it never reaches the Subject header intact.
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
