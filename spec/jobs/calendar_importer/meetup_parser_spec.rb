# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::Parsers::Meetup do
  describe "#download_calendar" do
    it "downloads and parses data correctly" do
      meetup_url = "https://www.meetup.com/tglondon/"

      VCR.use_cassette(:good_meetup_source) do
        calendar = build(
          :calendar,
          strategy: :event,
          name: :import_test_calendar,
          source: meetup_url
        )

        parser = described_class.new(calendar, url: meetup_url)

        data = parser.download_calendar
        expect(data.length).to eq(134)
      end
    end

    it "handles badly formed responses (non JSON)" do
      # non existant user
      bad_user_url = "https://www.meetup.com/haeKohtheuwae7uY6sie"

      VCR.use_cassette(:bad_meetup_gateway) do
        # FIXME: this is cheating a bit as we are knowingly building an
        #  invalid calendar that would never exist IRL. but we get around
        #  this by not saving it.

        calendar = build(
          :calendar,
          strategy: :event,
          name: :import_test_calendar,
          source: bad_user_url
        )

        parser = described_class.new(calendar, url: bad_user_url)

        expect do
          parser.download_calendar
        end.to raise_error(CalendarImporter::Exceptions::InaccessibleFeed)
      end
    end
  end
end
