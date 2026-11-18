# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Sites::EventRow, type: :component do
  let(:venue) { create(:partner, name: "Riverside Hall") }
  let(:organiser) { create(:partner, name: "Folk Club") }
  let(:neighbourhood) { double(name_from_badge_zoom: "Hulme") }
  let(:event) do
    double(id: 1, summary: "Sing-around", dtstart: Time.zone.parse("2026-11-19 19:00"), dtend: Time.zone.parse("2026-11-19 21:00"),
           organiser:, partner_at_location: venue, address: nil, rrule: nil, online_address: nil, neighbourhood:)
  end

  def row(**props)
    render_inline(described_class.new(event:, **props))
  end

  it "leads with the date, then the title, time, venue and organiser" do
    row

    expect(page).to have_css("time[data-part='date']", text: "19")
    expect(page).to have_css("[data-part='title'] a", text: "Sing-around")
    expect(page).to have_css("[data-variant='time']", text: "7pm – 9pm")
    expect(page).to have_css("[data-variant='place'] a", text: "Riverside Hall")
    expect(page).to have_css("[data-variant='organiser'] a", text: "Folk Club")
  end

  it "leaves out the venue and the organiser on their own partner pages" do
    row(context_partner: venue)
    expect(page).to have_no_css("[data-variant='place']")

    row(context_partner: organiser)
    expect(page).to have_no_css("[data-variant='organiser']")
  end

  it "shows the neighbourhood badge only on a site that shows neighbourhoods" do
    row
    expect(page).to have_no_css("[data-part='neighbourhood']")

    row(show_neighbourhoods: true)
    expect(page).to have_css("[data-part='neighbourhood']", text: "Hulme")
  end

  it "puts the word before a struck-through title for an event that is called off" do
    allow(event).to receive(:status).and_return("postponed")
    row

    expect(page).to have_css("[data-scope='event-status'][data-variant='postponed']", text: "Postponed")
    expect(page).to have_css("[data-part='title'] a.line-through", text: "Sing-around")
  end

  it "shows no status for an event that is going ahead" do
    allow(event).to receive(:status).and_return("scheduled")
    row

    expect(page).to have_no_css("[data-scope='event-status']")
    expect(page).to have_no_css("[data-part='title'] a.line-through")
  end
end
