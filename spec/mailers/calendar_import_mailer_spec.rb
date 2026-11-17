# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImportMailer, type: :mailer do
  let(:user) { create(:user, first_name: "Sam", email: "sam@example.org") }
  let(:organiser) { create(:partner, name: "Riverside Community Centre") }
  let(:calendar) do
    create(:calendar, name: "Riverside Events", organiser:).tap do |calendar|
      calendar.update_columns(calendar_state: "bad_source", critical_error: "The source could not be reached <b>today</b>") # rubocop:disable Rails/SkipsModelValidations
    end
  end
  let(:mail) { described_class.import_failed(calendar, user) }
  let(:body) { mail.body.encoded }

  it "goes to the one user, naming the calendar in the subject" do
    expect(mail.to).to eq(["sam@example.org"])
    expect(mail.subject).to eq(I18n.t("mailers.calendar_import.import_failed.subject", calendar: "Riverside Events"))
  end

  it "says which calendar stopped importing, and for which partner" do
    expect(body).to include(
      I18n.t("mailers.calendar_import.import_failed.intro", calendar: "Riverside Events", partner: "Riverside Community Centre")
        .gsub("'", "&#39;")
    )
  end

  it "gives the reason, escaped" do
    expect(body).to include(I18n.t("mailers.calendar_import.import_failed.reason.bad_source").gsub("'", "&#39;"))
    expect(body).to include("The source could not be reached &lt;b&gt;today&lt;/b&gt;")
  end

  it "explains an error state in its own words" do
    calendar.update_columns(calendar_state: "error") # rubocop:disable Rails/SkipsModelValidations

    expect(body).to include(I18n.t("mailers.calendar_import.import_failed.reason.error"))
  end

  it "links to the calendar in the admin" do
    expect(body).to include("http://admin.lvh.me:3000/calendars/#{calendar.id}/edit")
  end

  it "keeps newlines in the calendar name out of the subject header" do
    calendar.update_columns(name: "Riverside\r\nBcc: sneaky@example.com") # rubocop:disable Rails/SkipsModelValidations

    expect(mail.subject).not_to include("\n")
    expect(mail.bcc).to be_nil
  end
end
