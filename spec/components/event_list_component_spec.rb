# frozen_string_literal: true

require "rails_helper"

RSpec.describe EventListComponent, type: :component do
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
      events: events,
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

    expect(page).to have_css("ol.events")
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
    let(:next_event) do
      double(dtstart: Time.zone.parse("2024-01-20 10:00"))
    end

    let(:attrs) do
      {
        events: {},
        period: "day",
        next_date: next_event
      }
    end

    it "shows skip to next date link" do
      render_inline(described_class.new(**attrs))

      expect(page).to have_text("Skip to next date with events")
    end
  end
end
