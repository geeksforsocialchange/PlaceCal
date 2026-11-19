# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Sites::EventList, type: :component do
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

  let(:events) do
    { Date.new(2024, 1, 15) => [event] }
  end

  let(:attrs) do
    {
      events:,
      period: "day",
      show_neighbourhoods: false
    }
  end

  it "renders events grouped by day" do
    render_inline(described_class.new(**attrs))

    expect(page).to have_text("Monday 15 January")
    expect(page).to have_text("Community Meetup")
  end

  it "renders event list structure" do
    render_inline(described_class.new(**attrs))

    expect(page).to have_css("ol[data-scope='event-list'][data-part='day']")
  end

  context "with long-running events already on" do
    let(:exhibition) do
      double(id: 2, dtstart: Time.zone.parse("2023-12-01 10:00"), dtend: Time.zone.parse("2024-03-01 17:00"), summary: "Birds Exhibition",
             description: nil, partner_at_location: nil, address: nil, rrule: nil, neighbourhood: nil, online_address: nil)
    end

    it "lists them once above the days, under their own heading" do
      render_inline(described_class.new(**attrs, ongoing: [exhibition]))

      expect(page.all("h2").map(&:text)).to eq(["On now", "Monday 15 January"])
      expect(page).to have_css("ol[data-part='ongoing'] li", text: "Birds Exhibition", count: 1)
    end

    it "leads the rows with them" do
      render_inline(described_class.new(**attrs, ongoing: [exhibition], rows: true))

      expect(page.all("[data-part='title'] a").map(&:text)).to eq(["Birds Exhibition", "Community Meetup"])
    end

    it "shows them when no day has events" do
      render_inline(described_class.new(**attrs, events: {}, ongoing: [exhibition]))

      expect(page).to have_text("Birds Exhibition")
      expect(page).to have_no_text("No events with this selection")
    end
  end

  context "with no events" do
    let(:attrs) do
      {
        events: {},
        period: "day"
      }
    end

    it "shows no events message" do
      render_inline(described_class.new(**attrs))

      expect(page).to have_text("No events with this selection")
    end
  end

  context "with next_date provided" do
    let(:attrs) do
      {
        events: {},
        period: "day",
        next_date: Time.zone.parse("2024-01-20 10:00")
      }
    end

    it "shows skip to next date link" do
      render_inline(described_class.new(**attrs))

      expect(page).to have_text("Skip to next date with events")
    end
  end
end
