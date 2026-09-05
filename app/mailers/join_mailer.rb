# frozen_string_literal: true

class JoinMailer < ApplicationMailer
  def join_us(join)
    site = join.site
    # Mailer views inherit Views::Base, so their `t` resolves against
    # Current.theme. Current is request-scoped and is already reset by the time
    # a queued job runs, so set it here from the join's own site: the copy must
    # not depend on whether the mail was delivered in the request, from a job,
    # or from a console.
    Current.site = site
    Current.theme = PlaceCal::Theme.for(site)
    # A newline in the interpolated name would let it inject extra mail
    # headers, so it never reaches the Subject header intact.
    subject = if site
                t('join_mailer.join_us.subject_with_site', site: site.name.to_s.delete("\r\n"))
              else
                t('join_mailer.join_us.subject')
              end

    mail(to: site&.join_recipient || Join::DEFAULT_RECIPIENT, subject: subject) do |format|
      format.html { render Views::Mailers::Join::JoinUs.new(join: join) }
    end
  end
end
