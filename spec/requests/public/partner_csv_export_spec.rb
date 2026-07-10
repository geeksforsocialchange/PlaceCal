# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Partner events CSV export", type: :request do
  let(:partner) { create(:riverside_partner) }
  let(:calendar) { create(:calendar, organiser: partner) }

  describe "GET /partners/:id.csv" do
    let!(:upcoming_event) do
      create(:event,
             organiser: partner,
             calendar: calendar,
             summary: "Tea Dance",
             description: 'Dancing\, tea\; and \"biscuits\"\nAll welcome',
             dtstart: 2.days.from_now.at_beginning_of_hour,
             dtend: 2.days.from_now.at_beginning_of_hour + 2.hours)
    end
    let!(:past_event) do
      create(:event,
             organiser: partner,
             calendar: calendar,
             summary: "Ancient History",
             dtstart: 2.days.ago.at_beginning_of_hour,
             dtend: 2.days.ago.at_beginning_of_hour + 1.hour)
    end

    def parsed_csv
      get partner_url(partner, host: "lvh.me", format: :csv)
      expect(response).to be_successful
      CSV.parse(response.body, headers: true)
    end

    it "returns a CSV attachment" do
      get partner_url(partner, host: "lvh.me", format: :csv)
      expect(response).to be_successful
      expect(response.media_type).to eq("text/csv")
      expect(response.headers["Content-Disposition"]).to include("#{partner.slug}-events.csv")
    end

    it "has the Canva Bulk Create header row" do
      expect(parsed_csv.headers).to eq(
        ["Title", "Date", "Time", "Location", "Organiser", "More info", "Description"]
      )
    end

    it "includes upcoming events with poster-ready fields" do
      row = parsed_csv.find { |r| r["Title"] == "Tea Dance" }
      expect(row).to be_present
      expect(row["Date"]).to eq(upcoming_event.dtstart.strftime("%e %b %Y").strip)
      expect(row["Time"]).to eq(upcoming_event.time)
      expect(row["Location"]).to eq(upcoming_event.location)
      expect(row["Organiser"]).to eq(partner.name)
      expect(row["More info"]).to eq("https://placecal.org/events/#{upcoming_event.id}")
    end

    it "unescapes iCal sequences and flattens the description to one line" do
      row = parsed_csv.find { |r| r["Title"] == "Tea Dance" }
      expect(row["Description"]).to eq('Dancing, tea; and "biscuits" All welcome')
    end

    it "excludes past events" do
      titles = parsed_csv.map { |r| r["Title"] }
      expect(titles).not_to include("Ancient History")
    end

    context "when the partner has no events" do
      let(:empty_partner) { create(:partner) }

      it "returns just the header row" do
        get partner_url(empty_partner, host: "lvh.me", format: :csv)
        expect(response).to be_successful
        rows = CSV.parse(response.body, headers: true)
        expect(rows.count).to eq(0)
        expect(rows.headers).to include("Title")
      end
    end

    context "when the partner is hidden" do
      let(:hidden_partner) { create(:partner, hidden: true, hidden_reason: "Test", hidden_blame_id: 1) }

      it "redirects instead of serving the CSV" do
        get partner_url(hidden_partner, host: "lvh.me", format: :csv)
        expect(response).to redirect_to(root_path)
      end

      # Regression: redirect_to without return used to raise DoubleRenderError
      # for any non-HTML format on hidden partners.
      it "redirects the iCal feed too" do
        get partner_url(hidden_partner, host: "lvh.me", format: :ics)
        expect(response).to redirect_to(root_path)
      end
    end

    context "with awkward characters in event fields" do
      let!(:awkward_event) do
        create(:event,
               organiser: partner,
               calendar: calendar,
               summary: %(Knit, natter & "craft" night),
               dtstart: 3.days.from_now.at_beginning_of_hour,
               dtend: 3.days.from_now.at_beginning_of_hour + 1.hour)
      end

      it "round-trips commas and quotes safely" do
        titles = parsed_csv.map { |r| r["Title"] }
        expect(titles).to include(%(Knit, natter & "craft" night))
      end
    end
  end
end
