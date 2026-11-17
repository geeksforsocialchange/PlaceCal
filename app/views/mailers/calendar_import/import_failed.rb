# frozen_string_literal: true

class Views::Mailers::CalendarImport::ImportFailed < Views::Mailers::Base
  prop :calendar, Calendar, reader: :private
  prop :user, User, reader: :private
  prop :state, String, reader: :private
  prop :reason, _Nilable(String), reader: :private

  def email_content
    div { image_tag(image_url('logo.png'), height: '75') }

    p { "#{greeting_text(user)}," }

    p { t('mailers.calendar_import.import_failed.intro', calendar: calendar.name, partner: calendar.organiser&.name) }

    render_reason

    p { t('mailers.calendar_import.import_failed.retry') }

    p { link_to t('mailers.calendar_import.import_failed.link'), edit_admin_calendar_url(calendar, subdomain: Site::ADMIN_SUBDOMAIN) }

    p { raw t('mailers.calendar_import.import_failed.support_html', support: view_context.mail_to(t('contact.email'))) }

    p { t('mailers.sign_off') }
  end

  private

  def render_reason
    return if reason.blank?

    key = state == 'bad_source' ? :bad_source : :error
    p { t("mailers.calendar_import.import_failed.reason.#{key}") }
    blockquote { reason }
  end
end
