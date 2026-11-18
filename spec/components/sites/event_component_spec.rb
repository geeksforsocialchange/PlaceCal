# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Sites::Event, type: :component do
  let(:event_organiser) { nil }
  let(:event_place) { nil }
  let(:event_address) { double(street_address: "123 Main St") }
  let(:event_rrule) { nil }
  let(:event_online_address) { nil }
  let(:event_summary) { "Community Meetup" }
  let(:context_partner) { nil }
  let(:event_neighbourhood) { nil }
  let(:event_dtstart) { Time.zone.parse("2024-01-15 10:00") }
  let(:event_dtend) { Time.zone.parse("2024-01-15 12:00") }

  let(:event) do
    double(
      id: 1,
      dtstart: event_dtstart,
      dtend: event_dtend,
      summary: event_summary,
      description: "A great community event",
      organiser: event_organiser,
      partner_at_location: event_place,
      address: event_address,
      rrule: event_rrule,
      neighbourhood: event_neighbourhood,
      online_address: event_online_address
    )
  end

  def rendered
    render_inline(described_class.new(display_context: :list, event:, context_partner:))
  end

  it "renders event summary" do
    rendered
    expect(page).to have_text("Community Meetup")
  end

  context "with a long-running event" do
    let(:event_dtstart) { Time.zone.parse("2026-11-28 10:00") }
    let(:event_dtend) { Time.zone.parse("2027-01-17 17:00") }

    it "says when it runs until in place of the time range on a card" do
      rendered

      expect(page).to have_css("[data-variant='date'] time.dt-start", text: "28 Nov 2026")
      expect(page).to have_css("[data-variant='time'] time.dt-end[datetime^='2027-01-17']", text: "Until 17 Jan 2027")
      expect(page).to have_no_text("10am")
    end

    it "shows the date range and no time line on the page" do
      render_inline(described_class.new(display_context: :page, event:))

      expect(page).to have_css("[data-variant='date']", text: "28 Nov 2026 to 17 Jan 2027")
      expect(page).to have_no_css("[data-variant='time']")
    end

    it "ends on the day before a midnight end" do
      allow(event).to receive(:dtend).and_return(Time.zone.parse("2027-01-18 00:00"))
      rendered

      expect(page).to have_text("Until 17 Jan 2027")
    end
  end

  context "with an event of exactly 3 days" do
    let(:event_dtstart) { Time.zone.parse("2024-01-15 10:00") }
    let(:event_dtend) { Time.zone.parse("2024-01-18 10:00") }

    it "keeps its time range" do
      rendered

      expect(page).to have_css("[data-variant='time']", text: "10am – 18 Jan 10am")
      expect(page).to have_no_text("Until")
    end
  end

  it "leads the details with the date, then the time" do
    rendered
    variants = page.all('[data-scope="event"][data-part="detail"]').map { it["data-variant"] }
    expect(variants.first(2)).to eq(%w[date time])
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
      expect(page).to have_css('.h-event [data-scope="event"][data-part="header"]')
      expect(page).to have_no_css('[data-scope="event"][data-variant="page"]')
    end

    it "renders link to event" do
      rendered
      expect(page).to have_link("Community Meetup", href: "/events/1")
    end

    it "marks title with p-name and u-url classes" do
      render_inline(described_class.new(display_context: :list, event:))

      expect(page).to have_css("a.p-name.u-url", text: "Community Meetup")
    end

    it "renders time elements with dt-start and dt-end" do
      render_inline(described_class.new(display_context: :list, event:))

      expect(page).to have_css("time.dt-start[datetime]")
      expect(page).to have_css("time.dt-end[datetime]")
    end

    it "renders location with p-location class" do
      render_inline(described_class.new(display_context: :list, event:))

      expect(page).to have_css(".p-location")
    end

    it "does not use article tag" do
      render_inline(described_class.new(display_context: :list, event:))

      expect(page).not_to have_css("article")
    end

    context "when the event runs past midnight" do
      let(:event_dtstart) { Time.zone.local(Time.zone.now.year, 10, 23, 23) }
      let(:event_dtend) { Time.zone.local(Time.zone.now.year, 10, 24, 3) }

      it "shows only the start day and a plain time range" do
        rendered
        expect(page).to have_css('[data-scope="event"][data-part="detail"][data-variant="date"]', exact_text: /\A\s*23 Oct\s*\z/)
        expect(page).to have_css('[data-scope="event"][data-part="detail"][data-variant="time"]', text: /11pm \u2013\s+3am/)
      end
    end

    context "when the event ends as it starts, as for a feed with no end time" do
      let(:event_dtend) { event_dtstart }

      it "shows only the start time and no duration" do
        rendered
        expect(page).to have_css('[data-scope="event"][data-part="detail"][data-variant="time"]', exact_text: /\A\s*10am\s*\z/)
        expect(page).to have_no_css('[data-scope="event"][data-part="detail"][data-variant="duration"]')
      end
    end

    context "when the event lasts a day or more" do
      let(:event_dtstart) { Time.zone.local(Time.zone.now.year, 10, 23, 23) }
      let(:event_dtend) { Time.zone.local(Time.zone.now.year, 10, 25, 15) }

      it "shows the start day and puts the end date on the time line" do
        rendered
        expect(page).to have_css('[data-scope="event"][data-part="detail"][data-variant="date"]', exact_text: /\A\s*23 Oct\s*\z/)
        expect(page).to have_css('[data-scope="event"][data-part="detail"][data-variant="time"]', text: "11pm \u2013 25 Oct 3pm")
      end
    end
  end

  context "with page context" do
    it "renders page structure" do
      render_inline(described_class.new(display_context: :page, event:, site_tagline: "The Community Calendar"))
      expect(page).to have_css('[data-scope="event"][data-part="root"][data-variant="page"]')
    end

    it "wraps in h-event" do
      render_inline(described_class.new(display_context: :page, event:, site_tagline: "The Community Calendar"))

      expect(page).to have_css(".h-event")
    end

    it "renders hidden p-name u-url anchor" do
      render_inline(described_class.new(display_context: :page, event:, site_tagline: "The Community Calendar"))

      expect(page).to have_css("a.p-name.u-url[hidden]", text: "Community Meetup", visible: :hidden)
    end

    context "when the event has an organiser" do
      let(:event_organiser) { double(name: "Community Centre", id: 7, to_param: "community-centre") }

      it "puts the organiser under the title as the hero standfirst" do
        render_inline(described_class.new(display_context: :page, event:))

        expect(page).to have_css('[data-scope="hero"][data-part="standfirst"]', text: "By Community Centre")
        expect(page).to have_link("Community Centre", href: "/partners/community-centre")
      end
    end

    it "has no neighbourhood line, even when the event has a neighbourhood" do
      allow(event).to receive(:neighbourhood).and_return(double(shortname: "Moss Side", district: nil, name_from_badge_zoom: "Moss Side"))
      render_inline(described_class.new(display_context: :page, event:))

      expect(page).to have_no_text("Moss Side")
    end
  end

  context "organiser and place display" do
    let(:organiser) { Partner.new(id: 10, name: "Book Club", slug: "book-club") }
    let(:place) { Partner.new(id: 20, name: "Central Library", slug: "central-library") }
    let(:event_organiser) { organiser }
    let(:event_place) { place }

    it "shows both when organiser differs from place" do
      rendered
      expect(page).to have_css('[data-scope="event"][data-part="detail"][data-variant="organiser"]', text: "Book Club")
      expect(page).to have_css('[data-scope="event"][data-part="detail"][data-variant="place"]', text: "Central Library")
    end

    context "when the organiser's name is too long for the card" do
      let(:organiser) { Partner.new(id: 10, name: "Beachfront Community Garden Society", slug: "garden") }

      it "cuts it short on screen and gives screen readers the whole name" do
        rendered
        link = page.find('[data-variant="organiser"] a')
        expect(link).to have_css("span[aria-hidden='true']", text: "Beachfront Community G...")
        expect(link).to have_css("span.sr-only", text: "Beachfront Community Garden Society")
      end
    end

    context "when organiser is the same as place" do
      let(:event_organiser) { place }

      it "shows only the place" do
        rendered
        expect(page).to have_no_css('[data-scope="event"][data-part="detail"][data-variant="organiser"]')
        expect(page).to have_css('[data-scope="event"][data-part="detail"][data-variant="place"]', text: "Central Library")
      end
    end

    context "when on the organiser's partner page" do
      let(:context_partner) { organiser }

      it "hides the organiser but shows the place" do
        rendered
        expect(page).to have_no_css('[data-scope="event"][data-part="detail"][data-variant="organiser"]')
        expect(page).to have_css('[data-scope="event"][data-part="detail"][data-variant="place"]', text: "Central Library")
      end
    end

    context "when on the place's partner page" do
      let(:context_partner) { place }

      it "shows the organiser but hides the place" do
        rendered
        expect(page).to have_css('[data-scope="event"][data-part="detail"][data-variant="organiser"]', text: "Book Club")
        expect(page).to have_no_css('[data-scope="event"][data-part="detail"][data-variant="place"]')
      end
    end

    context "when there is no place but has an address" do
      let(:event_place) { nil }
      let(:event_address) { double(street_address: "456 Oak Ave") }

      it "shows organiser and address text" do
        rendered
        expect(page).to have_css('[data-scope="event"][data-part="detail"][data-variant="organiser"]', text: "Book Club")
        expect(page).to have_css('[data-scope="event"][data-part="detail"][data-variant="place"]', text: "456 Oak Ave")
      end
    end

    context "when there is no place and no address" do
      let(:event_place) { nil }
      let(:event_address) { nil }

      it "shows the organiser but no place" do
        rendered
        expect(page).to have_css('[data-scope="event"][data-part="detail"][data-variant="organiser"]', text: "Book Club")
        expect(page).to have_no_css('[data-scope="event"][data-part="detail"][data-variant="place"]')
      end
    end
  end

  context "with online event" do
    let(:event_online_address) { OnlineAddress.new(url: "https://example.org/live") }
    let(:event_address) { nil }

    it "shows online indicator" do
      rendered
      expect(page).to have_css('[data-scope="event"][data-part="detail"][data-variant="online"]', text: "Online")
      expect(page).to have_no_css('[data-scope="event"][data-part="detail"][data-variant="repeats"]')
    end

    context "on a known meeting service" do
      let(:event_online_address) { OnlineAddress.new(url: "https://meet.google.com/abc-defg-hij") }

      it "names the service" do
        rendered
        expect(page).to have_css('[data-scope="event"][data-part="detail"][data-variant="online"]', text: /\A\s*Google Meet\z/)
      end

      it "says Online on the service when asked to, as on a core event page" do
        render_inline(described_class.new(display_context: :page, event:, online_on: true))
        expect(page).to have_css('[data-scope="event"][data-part="detail"][data-variant="online"]', text: /\A\s*Online on Google Meet\z/)
      end
    end

    it "marks the event as online for themes" do
      rendered
      expect(page).to have_css('[data-scope="event"][data-part="root"][data-state="online"]')
    end
  end

  context "with repeating event" do
    let(:event_rrule) { [{ "table" => { "frequency" => "weekly" } }] }
    let(:event_address) { nil }

    it "shows repeat frequency" do
      rendered
      expect(page).to have_css('[data-scope="event"][data-part="detail"][data-variant="repeats"]', text: "Weekly")
      expect(page).to have_no_css('[data-scope="event"][data-part="detail"][data-variant="online"]')
      expect(page).to have_no_css('[data-scope="event"][data-state]')
    end
  end

  context "with repeating event imported under icalendar 2.13 (flat rule, no table key)" do
    let(:event_rrule) { [{ "frequency" => "WEEKLY", "by_day" => ["TH"] }] }
    let(:event_address) { nil }

    it "shows repeat frequency" do
      rendered
      expect(page).to have_text("Weekly")
    end
  end
end
