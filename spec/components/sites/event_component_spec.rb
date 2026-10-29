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
      expect(page).to have_css(".h-event .event__header")
      expect(page).to have_no_css(".event--full")
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
        expect(page).to have_css(".event__date", exact_text: /\A\s*23 Oct\s*\z/)
        expect(page).to have_css(".event__time", text: /11pm \u2013\s+3am/)
      end
    end

    context "when the event lasts a day or more" do
      let(:event_dtstart) { Time.zone.local(Time.zone.now.year, 10, 23, 23) }
      let(:event_dtend) { Time.zone.local(Time.zone.now.year, 10, 25, 15) }

      it "shows the start day and puts the end date on the time line" do
        rendered
        expect(page).to have_css(".event__date", exact_text: /\A\s*23 Oct\s*\z/)
        expect(page).to have_css(".event__time", text: "11pm \u2013 25 Oct 3pm")
      end
    end
  end

  context "with page context" do
    it "renders page structure" do
      render_inline(described_class.new(display_context: :page, event:, site_tagline: "The Community Calendar"))
      expect(page).to have_css(".event.event--full")
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

        expect(page).to have_css(".hero .hero__standfirst", text: "By Community Centre")
        expect(page).to have_link("Community Centre", href: "/partners/community-centre")
      end
    end

    it "renders no neighbourhood line when the event has no neighbourhood" do
      render_inline(described_class.new(display_context: :page, event:))

      expect(page).to have_no_css(".event__neighbourhood-line")
    end

    context "when the event has a neighbourhood" do
      let(:event_neighbourhood) do
        double(shortname: "Moss Side", district: double(shortname: "Manchester"), name_from_badge_zoom: "Moss Side")
      end

      it "renders the neighbourhood with its district" do
        render_inline(described_class.new(display_context: :page, event:))

        expect(page).to have_css(".event__detail.event__neighbourhood-line", text: "Moss Side, Manchester")
      end

      it "leaves it off the list card" do
        render_inline(described_class.new(display_context: :list, event:))

        expect(page).to have_no_css(".event__neighbourhood-line")
      end
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
      expect(page).to have_css(".event__online", text: "Online")
      expect(page).to have_no_css(".event__repeats")
    end
  end

  context "with repeating event" do
    let(:event_rrule) { [{ "table" => { "frequency" => "weekly" } }] }
    let(:event_address) { nil }

    it "shows repeat frequency" do
      rendered
      expect(page).to have_css(".event__repeats", text: "Weekly")
      expect(page).to have_no_css(".event__online")
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
