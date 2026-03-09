# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Event, type: :component do
  let(:event) do
    double(
      id: 1,
      dtstart: Time.zone.parse("2024-01-15 10:00"),
      dtend: Time.zone.parse("2024-01-15 12:00"),
      summary: "Community Meetup",
      description: "A great community event",
      partner_at_location: nil,
      address: double(street_address: "123 Main St"),
      rrule: nil,
      neighbourhood: nil,
      online_address: nil
    )
  end

  it "renders event summary" do
    render_inline(described_class.new(display_context: :list, event: event))

    expect(page).to have_text("Community Meetup")
  end

  it "renders event time" do
    render_inline(described_class.new(display_context: :list, event: event))

    expect(page).to have_text("10am")
    expect(page).to have_text("12pm")
  end

  it "renders event date" do
    render_inline(described_class.new(display_context: :list, event: event))

    expect(page).to have_text("15 Jan")
  end

  it "renders event duration" do
    render_inline(described_class.new(display_context: :list, event: event))

    expect(page).to have_text("2 hours")
  end

  it "renders address when present" do
    render_inline(described_class.new(display_context: :list, event: event))

    expect(page).to have_text("123 Main St")
  end

  context "with list context" do
    it "renders list structure" do
      render_inline(described_class.new(display_context: :list, event: event))

      expect(page).to have_css(".event.event--list")
      expect(page).to have_css(".event__header")
    end

    it "renders link to event" do
      render_inline(described_class.new(display_context: :list, event: event))

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

    context "when organiser differs from place" do
      let(:event) do
        double(
          id: 1,
          dtstart: Time.zone.parse("2024-01-15 10:00"),
          dtend: Time.zone.parse("2024-01-15 12:00"),
          summary: "Reading Group",
          description: "Weekly reading",
          organiser: organiser,
          partner_at_location: place,
          address: double(street_address: "123 Main St"),
          rrule: nil,
          neighbourhood: nil,
          online_address: nil
        )
      end

      it "shows both organiser and place" do
        render_inline(described_class.new(display_context: :list, event: event))

        expect(page).to have_css(".event__organiser", text: "Book Club")
        expect(page).to have_css(".event__location", text: "Central Library")
      end
    end

    context "when organiser is the same as place" do
      let(:event) do
        double(
          id: 1,
          dtstart: Time.zone.parse("2024-01-15 10:00"),
          dtend: Time.zone.parse("2024-01-15 12:00"),
          summary: "Library Tour",
          description: "Tour of the library",
          organiser: place,
          partner_at_location: place,
          address: double(street_address: "123 Main St"),
          rrule: nil,
          neighbourhood: nil,
          online_address: nil
        )
      end

      it "shows only the place, not a duplicate organiser" do
        render_inline(described_class.new(display_context: :list, event: event))

        expect(page).to have_no_css(".event__organiser")
        expect(page).to have_css(".event__location", text: "Central Library")
      end
    end

    context "when on the organiser's partner page" do
      let(:event) do
        double(
          id: 1,
          dtstart: Time.zone.parse("2024-01-15 10:00"),
          dtend: Time.zone.parse("2024-01-15 12:00"),
          summary: "Reading Group",
          description: "Weekly reading",
          organiser: organiser,
          partner_at_location: place,
          address: double(street_address: "123 Main St"),
          rrule: nil,
          neighbourhood: nil,
          online_address: nil
        )
      end

      it "hides the organiser but shows the place" do
        render_inline(described_class.new(display_context: :list, event: event, context_partner: organiser))

        expect(page).to have_no_css(".event__organiser")
        expect(page).to have_css(".event__location", text: "Central Library")
      end
    end

    context "when on the place's partner page" do
      let(:event) do
        double(
          id: 1,
          dtstart: Time.zone.parse("2024-01-15 10:00"),
          dtend: Time.zone.parse("2024-01-15 12:00"),
          summary: "Reading Group",
          description: "Weekly reading",
          organiser: organiser,
          partner_at_location: place,
          address: double(street_address: "123 Main St"),
          rrule: nil,
          neighbourhood: nil,
          online_address: nil
        )
      end

      it "shows the organiser but hides the place" do
        render_inline(described_class.new(display_context: :list, event: event, context_partner: place))

        expect(page).to have_css(".event__organiser", text: "Book Club")
        expect(page).to have_no_css(".event__location")
      end
    end

    context "when there is no place but has an address" do
      let(:event) do
        double(
          id: 1,
          dtstart: Time.zone.parse("2024-01-15 10:00"),
          dtend: Time.zone.parse("2024-01-15 12:00"),
          summary: "Pop-up Event",
          description: "One-off event",
          organiser: organiser,
          partner_at_location: nil,
          address: double(street_address: "456 Oak Ave"),
          rrule: nil,
          neighbourhood: nil,
          online_address: nil
        )
      end

      it "shows organiser and address text" do
        render_inline(described_class.new(display_context: :list, event: event))

        expect(page).to have_css(".event__organiser", text: "Book Club")
        expect(page).to have_css(".event__location", text: "456 Oak Ave")
      end
    end

    context "when there is no place and no address" do
      let(:event) do
        double(
          id: 1,
          dtstart: Time.zone.parse("2024-01-15 10:00"),
          dtend: Time.zone.parse("2024-01-15 12:00"),
          summary: "Virtual Workshop",
          description: "Online only",
          organiser: organiser,
          partner_at_location: nil,
          address: nil,
          rrule: nil,
          neighbourhood: nil,
          online_address: nil
        )
      end

      it "shows the organiser but no place" do
        render_inline(described_class.new(display_context: :list, event: event))

        expect(page).to have_css(".event__organiser", text: "Book Club")
        expect(page).to have_no_css(".event__location")
      end
    end
  end

  context "with online event" do
    let(:event) do
      double(
        id: 1,
        dtstart: Time.zone.parse("2024-01-15 10:00"),
        dtend: Time.zone.parse("2024-01-15 12:00"),
        summary: "Online Meetup",
        description: "A virtual event",
        partner_at_location: nil,
        address: nil,
        rrule: nil,
        neighbourhood: nil,
        online_address: "https://zoom.us/meeting"
      )
    end

    it "shows online indicator" do
      render_inline(described_class.new(display_context: :list, event: event))

      expect(page).to have_text("Online")
    end
  end

  context "with repeating event" do
    let(:event) do
      double(
        id: 1,
        dtstart: Time.zone.parse("2024-01-15 10:00"),
        dtend: Time.zone.parse("2024-01-15 12:00"),
        summary: "Weekly Meetup",
        description: "Happens every week",
        partner_at_location: nil,
        address: nil,
        rrule: [{ "table" => { "frequency" => "weekly" } }],
        neighbourhood: nil,
        online_address: nil
      )
    end

    it "shows repeat frequency" do
      render_inline(described_class.new(display_context: :list, event: event))

      expect(page).to have_text("Weekly")
    end
  end
end
