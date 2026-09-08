# frozen_string_literal: true

class JoinMailer < ApplicationMailer
  def join_us(contact_request)
    site = contact_request.site
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
                else
                  t('join_mailer.join_us.subject')
                end

      mail(to: site&.join_recipient || ContactRequest::DEFAULT_RECIPIENT, subject: subject) do |format|
        format.html { render Views::Mailers::Join::JoinUs.new(contact_request: contact_request) }
      end
    end
  end
end
