# frozen_string_literal: true

# Maps PanCal errors to user-facing messages. PanCal itself is I18n-free:
# its errors carry machine-readable code symbols, and this is the boundary
# where they become admin-facing copy.
module CalendarImporter::ErrorMessage
  def self.human(error)
    code = error.respond_to?(:code) ? error.code : nil

    case code
    when :forbidden, :not_found, :unreachable
      I18n.t("admin.calendars.wizard.source.#{code}")
    when :unreadable
      I18n.t('admin.calendars.wizard.source.unreadable', code: error.http_status)
    else
      error.message
    end
  end
end
