# frozen_string_literal: true

class CalendarImportMailer < ApplicationMailer
  def import_failed(calendar, user)
    # A newline in the name could inject mail headers.
    subject = t('mailers.calendar_import.import_failed.subject', calendar: calendar.name.to_s.delete("\r\n"))

    mail(to: user.email, subject:) do |format|
      format.html { render Views::Mailers::CalendarImport::ImportFailed.new(calendar:, user:) }
    end
  end
end
