# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImportMailer, type: :mailer do
  let(:user) { create(:user, first_name: "Sam", email: "sam@example.org") }
  let(:organiser) { create(:partner, name: "Riverside Community Centre") }
  let(:calendar) { create(:calendar, name: "Riverside Events", organiser:) }
  let(:state) { "bad_source" }
  let(:mail) { described_class.import_failed(calendar, user, state:, reason: "The source could not be reached <b>today</b>") }
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

  context "when the import failed with an error" do
    let(:state) { "error" }

    it "explains it in its own words" do
      expect(body).to include(I18n.t("mailers.calendar_import.import_failed.reason.error"))
    end
  end

  it "gives the failure as it was, even after the calendar's state has moved on" do
    mail
    calendar.update_columns(calendar_state: "error", critical_error: "A later problem") # rubocop:disable Rails/SkipsModelValidations

    expect(body).to include(I18n.t("mailers.calendar_import.import_failed.reason.bad_source").gsub("'", "&#39;"))
    expect(body).to include("The source could not be reached &lt;b&gt;today&lt;/b&gt;")
    expect(body).not_to include("A later problem")
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
