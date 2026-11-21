# frozen_string_literal: true

# Built in memory, so viewing a preview writes nothing to the database.
class CalendarImportMailerPreview < ActionMailer::Preview
  def import_failed
    CalendarImportMailer.import_failed(calendar, user, state: "bad_source", reason: I18n.t("admin.calendars.wizard.source.unreachable"))
  end

  def import_failed_with_error
    CalendarImportMailer.import_failed(
      calendar, user,
      state: "error",
      reason: "Calendar URL returned un-parsable data for calendar Riverside Community Events (id 1): unexpected token"
    )
  end

  private

  def calendar
    Calendar.new(id: 1, name: "Riverside Community Events", organiser: Partner.new(name: "Riverside Community Centre"))
  end

  def user
    User.new(first_name: "Sam", last_name: "Taylor", email: "sam@example.org")
  end
end
