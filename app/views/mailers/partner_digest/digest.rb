# frozen_string_literal: true

class Views::Mailers::PartnerDigest::Digest < Views::Mailers::Base
  register_value_helper :greeting_text

  prop :digest, PartnerDigest, reader: :private
  prop :confirm_url, String, reader: :private
  prop :preferences_url, String, reader: :private
  prop :sign_in_url, String, reader: :private
  prop :password_reset_url, String, reader: :private

  def email_content
    p { "#{greeting_text(digest.user)}," }

    render_intro
    render_confirm_button
    digest.sections.each { |section| render_section(section) }
    render_account_help
    render_footer
  end

  private

  def render_intro
    if digest.first_contact?
      p { t('mailers.partner_digest.first_contact.what_is_placecal') }
      p do
        plain t('mailers.partner_digest.first_contact.why_this_email')
        plain ' '
        a(href: privacy_url) { t('mailers.partner_digest.first_contact.privacy_link') }
        plain '.'
      end
      p do
        plain t('mailers.partner_digest.first_contact.preferences_note')
        plain ' '
        a(href: preferences_url) { t('mailers.partner_digest.preferences_link') }
        plain '.'
      end
    else
      p { t('mailers.partner_digest.intro') }
    end
  end

  def render_confirm_button
    p { b { t('mailers.partner_digest.confirm.prompt') } }
    p do
      a(href: confirm_url,
        style: 'display:inline-block;padding:12px 24px;background-color:#e85e3d;color:#ffffff;' \
               'text-decoration:none;border-radius:24px;font-weight:bold;') do
        t('mailers.partner_digest.confirm.button')
      end
    end
  end

  def render_section(section)
    h2 { section.partner.name }
    p { a(href: section.partner.permalink) { t('mailers.partner_digest.view_listing') } }

    case section.status
    when :healthy then render_healthy(section)
    when :failing then render_failing(section)
    when :no_calendar then render_no_calendar(section)
    end
  end

  def render_healthy(section)
    p do
      plain t('mailers.partner_digest.healthy.status')
      if section.last_import_at
        plain ' '
        plain t('mailers.partner_digest.healthy.last_synced',
                ago: time_ago_in_words(section.last_import_at))
      end
    end
    render_events(section.upcoming_events,
                  empty_key: 'mailers.partner_digest.healthy.no_upcoming_events')
    p { a(href: section.partner.permalink) { t('mailers.partner_digest.healthy.see_all') } }
  end

  def render_failing(section)
    section.failing_calendars.each do |calendar|
      p do
        plain t('mailers.partner_digest.failing.problem',
                name: calendar.name,
                reason: failing_reason(calendar))
      end
      p { a(href: edit_admin_calendar_url(calendar, subdomain: Site::ADMIN_SUBDOMAIN)) { t('mailers.partner_digest.failing.fix_link') } }
    end
  end

  def render_no_calendar(section)
    p { t('mailers.partner_digest.no_calendar.status') }
    p { a(href: edit_admin_partner_url(section.partner, subdomain: Site::ADMIN_SUBDOMAIN)) { t('mailers.partner_digest.no_calendar.connect_link') } }
    return if section.upcoming_events.empty?

    p { t('mailers.partner_digest.no_calendar.manual_events') }
    render_events(section.upcoming_events)
  end

  def render_events(events, empty_key: nil)
    if events.empty?
      p { t(empty_key) } if empty_key
      return
    end

    ul do
      events.each do |event|
        li do
          plain "#{l(event.dtstart, format: :datetime)} — "
          a(href: event.permalink) { event.summary }
        end
      end
    end
  end

  def render_account_help
    h2 { t('mailers.partner_digest.account.heading') }
    p { t('mailers.partner_digest.account.you_have_an_account', email: digest.user.email) }
    p { a(href: sign_in_url) { t('mailers.partner_digest.account.sign_in') } }
    p { a(href: password_reset_url) { t('mailers.partner_digest.account.forgotten_password') } }
  end

  def render_footer
    p do
      a(href: preferences_url) { t('mailers.partner_digest.preferences_link') }
    end
    p { t('mailers.partner_digest.sign_off') }
  end

  def failing_reason(calendar)
    t("mailers.partner_digest.failing.reasons.#{PartnerDigest.failing_reason_key(calendar)}")
  end

  # @return [String]
  def l(value, **)
    I18n.l(value, **)
  end
end
