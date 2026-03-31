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

    it "marks title with p-name and u-url classes" do
      render_inline(described_class.new(display_context: :list, event: event))

      expect(page).to have_css("a.p-name.u-url", text: "Community Meetup")
    end

    it "renders time elements with dt-start and dt-end" do
      render_inline(described_class.new(display_context: :list, event: event))

      expect(page).to have_css("time.dt-start[datetime]")
      expect(page).to have_css("time.dt-end[datetime]")
    end

    it "renders location with p-location class" do
      render_inline(described_class.new(display_context: :list, event: event))

      expect(page).to have_css(".p-location")
    end

    it "does not use article tag" do
      render_inline(described_class.new(display_context: :list, event: event))

      expect(page).not_to have_css("article")
    end
  end

  context "with page context" do
    it "renders page structure" do
      render_inline(described_class.new(display_context: :page, event: event, site_tagline: "The Community Calendar"))

      expect(page).to have_css(".event.event--full")
    end

    it "wraps in h-event" do
      render_inline(described_class.new(display_context: :page, event: event, site_tagline: "The Community Calendar"))

      expect(page).to have_css(".h-event")
    end

    it "renders hidden p-name u-url anchor" do
      render_inline(described_class.new(display_context: :page, event: event, site_tagline: "The Community Calendar"))

      expect(page).to have_css("a.p-name.u-url[hidden]", text: "Community Meetup", visible: :hidden)
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
