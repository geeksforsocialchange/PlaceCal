# frozen_string_literal: true

class Views::Mailers::PartnerDigest::DigestText < Views::TextBase
  register_value_helper :greeting_text

  prop :digest, PartnerDigest, reader: :private
  prop :confirm_url, String, reader: :private
  prop :preferences_url, String, reader: :private
  prop :sign_in_url, String, reader: :private
  prop :password_reset_url, String, reader: :private

  def text_content
    [
      "#{greeting_text(digest.user)},",
      intro_text,
      confirm_text,
      *digest.sections.map { |section| section_text(section) },
      account_text,
      footer_text
    ].join("\n\n")
  end

  private

  def intro_text
    if digest.first_contact?
      [
        t('mailers.partner_digest.first_contact.what_is_placecal'),
        "#{t('mailers.partner_digest.first_contact.why_this_email')} #{privacy_url}",
        "#{t('mailers.partner_digest.first_contact.preferences_note')} #{preferences_url}"
      ].join("\n\n")
    else
      t('mailers.partner_digest.intro')
    end
  end

  def confirm_text
    "#{t('mailers.partner_digest.confirm.prompt')}\n" \
      "#{t('mailers.partner_digest.confirm.button')}: #{confirm_url}"
  end

  def section_text(section)
    lines = ["## #{section.partner.name}",
             "#{t('mailers.partner_digest.view_listing')}: #{section.partner.permalink}"]

    case section.status
    when :healthy then lines.concat(healthy_lines(section))
    when :failing then lines.concat(failing_lines(section))
    when :no_calendar then lines.concat(no_calendar_lines(section))
    end

    lines.join("\n")
  end

  def healthy_lines(section)
    lines = [t('mailers.partner_digest.healthy.status')]
    if section.last_import_at
      lines << t('mailers.partner_digest.healthy.last_synced',
                 ago: distance_of_time_in_words(section.last_import_at, Time.current))
    end
    if section.upcoming_events.empty?
      lines << t('mailers.partner_digest.healthy.no_upcoming_events')
    else
      lines.concat(event_lines(section.upcoming_events))
    end
    lines << "#{t('mailers.partner_digest.healthy.see_all')}: #{section.partner.permalink}"
  end

  def failing_lines(section)
    section.failing_calendars.flat_map do |calendar|
      [
        t('mailers.partner_digest.failing.problem', name: calendar.name, reason: failing_reason(calendar)),
        "#{t('mailers.partner_digest.failing.fix_link')}: " \
        "#{edit_admin_calendar_url(calendar, subdomain: Site::ADMIN_SUBDOMAIN)}"
      ]
    end
  end

  def no_calendar_lines(section)
    lines = [
      t('mailers.partner_digest.no_calendar.status'),
      "#{t('mailers.partner_digest.no_calendar.connect_link')}: " \
      "#{edit_admin_partner_url(section.partner, subdomain: Site::ADMIN_SUBDOMAIN)}"
    ]
    if section.upcoming_events.any?
      lines << t('mailers.partner_digest.no_calendar.manual_events')
      lines.concat(event_lines(section.upcoming_events))
    end
    lines
  end

  def event_lines(events)
    events.map { |event| "- #{I18n.l(event.dtstart, format: :datetime)} — #{event.summary}: #{event.permalink}" }
  end

  def account_text
    [
      t('mailers.partner_digest.account.heading'),
      t('mailers.partner_digest.account.you_have_an_account', email: digest.user.email),
      "#{t('mailers.partner_digest.account.sign_in')}: #{sign_in_url}",
      "#{t('mailers.partner_digest.account.forgotten_password')}: #{password_reset_url}"
    ].join("\n")
  end

  def footer_text
    "#{t('mailers.partner_digest.preferences_link')}: #{preferences_url}\n\n" \
      "#{t('mailers.partner_digest.sign_off')}"
  end

  def failing_reason(calendar)
    state = PartnerDigest::FAILING_STATES.include?(calendar.calendar_state.to_s) ? calendar.calendar_state : 'error'
    t("mailers.partner_digest.failing.reasons.#{state}")
  end
end
