# frozen_string_literal: true

# Built in memory, so viewing a preview writes nothing to the database.
class CalendarImportMailerPreview < ActionMailer::Preview
  def import_failed
    CalendarImportMailer.import_failed(calendar(:bad_source, I18n.t("admin.calendars.wizard.source.unreachable")), user)
  end

  def import_failed_with_error
    CalendarImportMailer.import_failed(
      calendar(:error, "Calendar URL returned un-parsable data for calendar Riverside Community Events (id 1): unexpected token"),
      user
    )
  end

  private

  def calendar(state, critical_error)
    Calendar.new(id: 1, name: "Riverside Community Events", calendar_state: state, critical_error:,
                 organiser: Partner.new(name: "Riverside Community Centre"))
  end

  def user
    User.new(first_name: "Sam", last_name: "Taylor", email: "sam@example.org")
  end
end
