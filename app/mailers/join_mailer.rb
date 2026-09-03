# frozen_string_literal: true

class JoinMailer < ApplicationMailer
  def join_us(join)
    site = join.site
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
