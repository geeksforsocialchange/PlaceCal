# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Event, type: :component do
  let(:event_organiser) { nil }
  let(:event_place) { nil }
  let(:event_address) { double(street_address: "123 Main St") }
  let(:event_rrule) { nil }
  let(:event_online_address) { nil }
  let(:event_summary) { "Community Meetup" }
  let(:context_partner) { nil }

  let(:event) do
    double(
      id: 1,
      dtstart: Time.zone.parse("2024-01-15 10:00"),
      dtend: Time.zone.parse("2024-01-15 12:00"),
      summary: event_summary,
      description: "A great community event",
      organiser: event_organiser,
      partner_at_location: event_place,
      address: event_address,
      rrule: event_rrule,
      neighbourhood: nil,
      online_address: event_online_address
    )
  end

  def rendered
    render_inline(described_class.new(display_context: :list, event: event, context_partner: context_partner))
  end

  it "renders event summary" do
    rendered
    expect(page).to have_text("Community Meetup")
  end

  it "renders event time" do
    rendered
    expect(page).to have_text("10am")
    expect(page).to have_text("12pm")
  end

  it "renders event date" do
    rendered
    expect(page).to have_text("15 Jan")
  end

  it "renders event duration" do
    rendered
    expect(page).to have_text("2 hours")
  end

  it "renders address when present" do
    rendered
    expect(page).to have_text("123 Main St")
  end

  context "with list context" do
    it "renders list structure" do
      rendered
      expect(page).to have_css(".event.event--list")
      expect(page).to have_css(".event__header")
    end

    it "renders link to event" do
      rendered
      expect(page).to have_link("Community Meetup", href: "/events/1")
    end
  end

  context "with page context" do
    it "renders page structure" do
      render_inline(described_class.new(display_context: :page, event: event, site_tagline: "The Community Calendar"))
      expect(page).to have_css(".event.event--full")
    end
  end

  context "organiser and place display" do
    let(:organiser) { Partner.new(id: 10, name: "Book Club", slug: "book-club") }
    let(:place) { Partner.new(id: 20, name: "Central Library", slug: "central-library") }
    let(:event_organiser) { organiser }
    let(:event_place) { place }

    it "shows both when organiser differs from place" do
      rendered
      expect(page).to have_css(".event__organiser", text: "Book Club")
      expect(page).to have_css(".event__location", text: "Central Library")
    end

    context "when organiser is the same as place" do
      let(:event_organiser) { place }

      it "shows only the place" do
        rendered
        expect(page).to have_no_css(".event__organiser")
        expect(page).to have_css(".event__location", text: "Central Library")
      end
    end

    context "when on the organiser's partner page" do
      let(:context_partner) { organiser }

      it "hides the organiser but shows the place" do
        rendered
        expect(page).to have_no_css(".event__organiser")
        expect(page).to have_css(".event__location", text: "Central Library")
      end
    end

    context "when on the place's partner page" do
      let(:context_partner) { place }

      it "shows the organiser but hides the place" do
        rendered
        expect(page).to have_css(".event__organiser", text: "Book Club")
        expect(page).to have_no_css(".event__location")
      end
    end

    context "when there is no place but has an address" do
      let(:event_place) { nil }
      let(:event_address) { double(street_address: "456 Oak Ave") }

      it "shows organiser and address text" do
        rendered
        expect(page).to have_css(".event__organiser", text: "Book Club")
        expect(page).to have_css(".event__location", text: "456 Oak Ave")
      end
    end

    context "when there is no place and no address" do
      let(:event_place) { nil }
      let(:event_address) { nil }

      it "shows the organiser but no place" do
        rendered
        expect(page).to have_css(".event__organiser", text: "Book Club")
        expect(page).to have_no_css(".event__location")
      end
    end
  end

  context "with online event" do
    let(:event_online_address) { "https://zoom.us/meeting" }
    let(:event_address) { nil }

    it "shows online indicator" do
      rendered
      expect(page).to have_text("Online")
    end
  end

  context "with repeating event" do
    let(:event_rrule) { [{ "table" => { "frequency" => "weekly" } }] }
    let(:event_address) { nil }

    it "shows repeat frequency" do
      rendered
      expect(page).to have_text("Weekly")
    end
  end
end
