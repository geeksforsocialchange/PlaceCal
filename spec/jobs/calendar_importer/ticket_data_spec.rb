# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Ticket link, price and sold-out state from each source" do
  def imported(parser, cassette, url, **calendar_attributes)
    VCR.use_cassette(cassette, allow_playback_repeats: true) do
      parser.new(build(:calendar, source: url, **calendar_attributes)).calendar_to_events.events
    end
  end

  def ticket_data(event)
    event.attributes.slice(:ticket_url, :price_from, :price_currency, :sold_out)
  end

  def linked_data_event(offers)
    data = { "@type" => "Event", "name" => "An event", "url" => "https://example.com/1", "startDate" => "2030-02-01T19:00", "offers" => offers }
    html = %(<script type="application/ld+json">#{{ '@context' => 'https://schema.org', '@graph' => [data] }.to_json}</script>)
    consumer = CalendarImporter::Parsers::LdJson::EventConsumer.new
    consumer.consume(CalendarImporter::Parsers::Base.parse_ld_json_document(Nokogiri::HTML(html)))
    consumer.events.first
  end

  describe "Ticket Tailor" do
    let(:events) do
      imported(CalendarImporter::Parsers::Tickettailor, :tickettailor_events, "https://www.tickettailor.com/events/testorg",
               api_token: "sk_test_placeholder")
    end

    it "reads the checkout link, the lowest ticket price in pounds, and availability" do
      expect(ticket_data(events.first)).to eq(
        ticket_url: "https://www.tickettailor.com/checkout/view-event/id/4668136/chk/0252/",
        price_from: 0, price_currency: "GBP", sold_out: false
      )
      expect(events.map { |event| ticket_data(event)[:sold_out] }).to all(be(false))
    end

    def event_with(attributes)
      CalendarImporter::Events::TickettailorEvent.new({ "id" => "ev_1", "currency" => "gbp" }.merge(attributes))
    end

    it "converts pence, preferring ticket types on sale" do
      event = event_with("ticket_types" => [{ "price" => 250, "status" => "sold_out" }, { "price" => 400, "status" => "on_sale" },
                                            { "price" => 800, "status" => "on_sale" }])

      expect(ticket_data(event)).to include(price_from: BigDecimal("4.00"), price_currency: "GBP")
    end

    it "says sold out only for a sold-out status, and leaves closed or not-yet-open sales unknown" do
      expect(event_with("tickets_available" => "false", "unavailable" => "true", "unavailable_status" => "sold_out").sold_out).to be(true)
      expect(event_with("tickets_available" => "false").sold_out).to be_nil
      expect(event_with("tickets_available" => "true").sold_out).to be(false)
    end
  end

  describe "Wix" do
    let(:events) do
      VCR.use_cassette(:wix_events) do
        allow(CalendarImporter::Parsers::Base).to receive(:read_http_source).and_call_original
        allow(CalendarImporter::Parsers::Base).to receive(:read_http_source)
          .with(a_string_including("/event-details/")).and_return("<html></html>")
        CalendarImporter::Parsers::Wix.new(build(:calendar, source: "https://www.socialrefuge.com/event-list", importer_mode: "wix"))
                                      .calendar_to_events.events
      end
    end

    it "reads the lowest ticket price, its currency and sold-out state" do
      expect(ticket_data(events.first)).to eq(ticket_url: nil, price_from: BigDecimal("25.63"), price_currency: "GBP", sold_out: false)
    end

    it "reads the two sold-out events, which have no price" do
      sold_out = events.select { |event| event.attributes[:sold_out] }

      expect(sold_out.map(&:summary)).to eq(["Queer Lit Book Club"] * 2)
      expect(sold_out.map { |event| event.attributes[:price_from] }).to all(be_nil)
    end
  end

  describe "OutSavvy" do
    def events(cassette, organiser)
      imported(CalendarImporter::Parsers::Outsavvy, cassette, "https://www.outsavvy.com/organiser/#{organiser}")
    end

    it "takes the lowest ticket on sale, not the summary range or a sold-out ticket" do
      event = events(:outsavvy_cancelled_event, "a-whole-orange").find { |e| e.summary.start_with?("COMMUNICATION IN DATING") }

      expect(ticket_data(event)).to eq(ticket_url: nil, price_from: 15, price_currency: "GBP", sold_out: false)
      expect(event.attributes[:publisher_url]).to eq("https://www.outsavvy.com/event/28861/communication-in-dating-47-queer-zine-dating-workshop-series")
    end

    it "reads a free ticket among paid ones as a lowest price of 0" do
      expect(ticket_data(events(:outsavvy_publisher_url, "ldn-queer-mart").sole)).to include(price_from: 0, price_currency: "GBP", sold_out: false)
    end

    it "reads OutOfStock as sold out, and takes the lowest sold-out ticket when none is on sale" do
      by_date = events(:outsavvy_cancelled_event, "a-whole-orange").index_by { |e| [e.summary[0, 10], e.start_time.to_date.iso8601] }

      expect(ticket_data(by_date[["MONTHLY MI", "2023-10-18"]])).to include(price_from: 5, sold_out: true)
      expect(ticket_data(by_date[["MONTHLY MI", "2025-10-15"]])).to include(price_from: 0, sold_out: false)
    end

    it "stores no price for a range of 0 to 0 with no tickets" do
      sapphic = events(:outsavvy_cancelled_event, "a-whole-orange").find { |e| e.start_time.to_date == Date.new(2025, 9, 11) }

      expect(ticket_data(sapphic)).to include(price_from: nil, price_currency: nil, sold_out: true)
    end
  end

  describe "JSON-LD" do
    it "reads a generic site's single offer, whose link is the series page rather than the date's" do
      event = imported(CalendarImporter::Parsers::LdJson, :heart_of_torbay_events, "https://www.heartoftorbaycic.com/events/").sole

      expect(ticket_data(event)).to eq(
        ticket_url: "https://www.heartoftorbaycic.com/events/tidy-home-tidy-mind-support-group-monthly/",
        price_from: 0, price_currency: "GBP", sold_out: false
      )
    end

    it "leaves out a ticket link that is the event's own page" do
      event = linked_data_event({ "@type" => "Offer", "url" => "https://example.com/1", "price" => "0" })

      expect(ticket_data(event)).to eq(ticket_url: nil, price_from: 0, price_currency: nil, sold_out: nil)
    end

    it "stores nothing from dice.fm's empty offers" do
      events = imported(CalendarImporter::Parsers::LdJson, :dice_fm_events, "https://dice.fm/venue/folklore-2or7")

      expect(events.map { |event| ticket_data(event) }.uniq).to eq([{ ticket_url: nil, price_from: nil, price_currency: nil, sold_out: nil }])
    end

    it "uses an AggregateOffer's lowPrice when it lists no tickets" do
      event = linked_data_event({ "@type" => "AggregateOffer", "lowPrice" => "7.50", "highPrice" => "12", "priceCurrency" => "gbp",
                                  "availability" => "https://schema.org/SoldOut", "url" => "https://example.com/tickets" })

      expect(ticket_data(event)).to eq(ticket_url: "https://example.com/tickets", price_from: BigDecimal("7.5"), price_currency: "GBP",
                                       sold_out: true)
    end

    it "drops a price with no currency, and keeps availability unknown when no offer states it" do
      expect(ticket_data(linked_data_event({ "@type" => "Offer", "price" => "5" }))).to eq(
        ticket_url: nil, price_from: nil, price_currency: nil, sold_out: nil
      )
    end
  end

  describe "Eventbrite" do
    it "stores free events as a price of 0, and nothing for the rest" do
      events = imported(CalendarImporter::Parsers::Eventbrite, :eventbrite_events, "https://www.eventbrite.co.uk/o/queer-lit-social-refuge-48062165483")

      expect(events.map { |event| ticket_data(event) }.uniq).to contain_exactly(
        { ticket_url: nil, price_from: 0, price_currency: nil, sold_out: nil },
        { ticket_url: nil, price_from: nil, price_currency: nil, sold_out: nil }
      )
    end
  end

  describe "importing" do
    it "saves the ticket data on each event" do
      calendar = create(:calendar, source: "https://www.tickettailor.com/events/testorg", api_token: "sk_test_placeholder", strategy: "no_location")

      Timecop.travel(Time.zone.local(2024, 10, 1)) do
        VCR.use_cassette(:tickettailor_events, allow_playback_repeats: true) do
          calendar.update!(calendar_state: "in_worker")
          CalendarImporter::CalendarImporterTask.new(calendar, Time.zone.today, true).run
        end
      end

      expect(calendar.events).to be_present
      expect(calendar.events.pluck(:price_from, :price_currency, :sold_out).uniq).to eq([[0, "GBP", false]])
      expect(calendar.events.pluck(:ticket_url)).to all(start_with("https://www.tickettailor.com/checkout/"))
    end
  end
end
