# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin calendar sources", type: :request do
  def sources_link(body)
    Nokogiri::HTML(body).css("a[href='#{sources_admin_calendars_path}']").find { |link| link.ancestors("nav").empty? }
  end

  describe "GET /calendars/sources" do
    it "sends a signed-out visitor to log in" do
      get sources_admin_calendars_url(host: admin_host)
      expect(response).to redirect_to(new_user_session_path)
    end

    it "turns away a user who can't add calendars" do
      sign_in create(:citizen_user)
      get sources_admin_calendars_url(host: admin_host)
      expect(response).to redirect_to(admin_root_path)
    end

    %i[root_user partner_admin neighbourhood_admin].each do |role|
      it "shows the table to a #{role.to_s.humanize(capitalize: false)}" do
        sign_in create(role)
        get sources_admin_calendars_url(host: admin_host)
        expect(response).to be_successful
      end
    end

    context "when signed in" do
      before do
        sign_in create(:partner_admin)
        get sources_admin_calendars_url(host: admin_host)
      end

      let(:page) { Nokogiri::HTML(response.body) }
      let(:headings) { page.css("thead th").map { |heading| heading.text.strip } }
      let(:rows) do
        page.css("tbody tr").to_h do |row|
          [row.at_css("th div").text.strip, headings.drop(1).zip(row.css("td").map { |cell| cell.text.strip }).to_h]
        end
      end

      it "has a column for each event field, in the words the admin and event pages use" do
        expect(headings).to eq(["Source", "Title", "Description", "Start", "End", "Repeats", "Event location", "Event webpage",
                                "Meeting link", "Spaces available", "Ticket link", "Price", "Sold out", "Cancelled or postponed", "Image", "Source categories",
                                "Source organiser"])
      end

      it "has a row for every source, hidden ones included" do
        expect(rows.keys).to match_array(CalendarImporter::CalendarImporter::PARSERS.map { |parser| parser::NAME })
      end

      it "links each source to its handbook page" do
        links = page.css("tbody th a").to_h { |link| [link.text.strip, link[:href]] }
        expect(links.size).to eq(CalendarImporter::CalendarImporter::PARSERS.size)
        expect(links["Ticket Tailor"]).to eq("https://handbook.placecal.org/reference/supported-calendar-sources/ticket-tailor")
      end

      it "is linked from the admin menu" do
        expect(Nokogiri::HTML(response.body).at_css("nav a[href='#{sources_admin_calendars_path}']")).to be_present
      end

      it "fills each cell from the source's event class", :aggregate_failures do
        expect(rows["Meetup"]).to eq(rows["Generic iCal / .ics"])
        expect(rows["Generic iCal / .ics"]["Title"]).to eq("SUMMARY")
        expect(rows["Ticket Solve"]["Spaces available"]).to eq("status")
        expect(rows["Ticket Solve"]["End"]).to eq("Not imported")
        expect(rows["OutSavvy"]["Cancelled or postponed"]).to eq("eventStatus")
        expect(rows["Wix Events"]["Image"]).to eq("mainImage.url")
        expect(rows["Wix Events"]["Source organiser"]).to eq("Not imported")
        expect(rows["Ticket Solve"]["Event webpage"]).to eq("url")
        expect(rows["Resident Advisor"]["Cancelled or postponed"]).to eq("title")
        expect(rows["TicketSource"]["Image"]).to eq("images.src")
        expect(rows["Ticket Tailor"]["Ticket link"]).to eq("checkout_url")
        expect(rows["Wix Events"]["Sold out"]).to eq("registration.ticketing.soldOut")
        expect(rows["Eventbrite"]["Price"]).to eq("is_free")
        expect(rows["Ticket Solve"]["Sold out"]).to eq("Not imported")
      end
    end
  end

  it "is linked from the new calendar wizard" do
    sign_in create(:partner_admin)
    get new_admin_calendar_url(host: admin_host)
    expect(sources_link(response.body)&.text).to eq("See what each source imports")
  end

  it "is linked from a calendar's Source tab" do
    sign_in create(:root_user)
    calendar = build(:calendar)
    allow(calendar).to receive(:check_source_reachable)
    calendar.save!

    get edit_admin_calendar_url(calendar, host: admin_host)
    expect(sources_link(response.body)&.text).to eq("See what each source imports")
  end
end
