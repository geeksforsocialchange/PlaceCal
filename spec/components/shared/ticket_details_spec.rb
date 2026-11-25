# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Shared::TicketDetails, type: :component do
  let(:tickets) { {} }
  let(:status) { "confirmed" }
  let(:event) do
    double(id: 1, summary: "Ceilidh", dtstart: Time.zone.parse("2026-11-19 19:00"), dtend: Time.zone.parse("2026-11-19 21:00"),
           description: nil, organiser: nil, partner_at_location: nil, address: nil, rrule: nil, online_address: nil, neighbourhood: nil,
           status:, price_from: nil, price_currency: nil, sold_out: nil, **tickets)
  end

  {
    "the site row" => ->(event) { Components::Sites::EventRow.new(event:) },
    "the directory row" => ->(event) { Components::Directory::EventRow.new(event:) }
  }.each do |name, build|
    describe "on #{name}" do
      def label = page.find("[data-icon-name='ticket']").find(:xpath, "..").text.strip

      before { render_inline(build.call(event)) }

      context "when the event is free" do
        let(:tickets) { { price_from: BigDecimal(0) } }

        it { expect(label).to eq(I18n.t("events.tickets.free")) }
      end

      context "when the event has a price" do
        let(:tickets) { { price_from: BigDecimal(5), price_currency: "GBP" } }

        it { expect(label).to eq("From £5") }
      end

      context "when the event is sold out" do
        let(:tickets) { { price_from: BigDecimal(5), price_currency: "GBP", sold_out: true } }

        it "says sold out in place of the price" do
          expect(label).to eq(I18n.t("events.tickets.sold_out"))
        end
      end

      context "when tickets are still available" do
        let(:tickets) { { price_from: BigDecimal(5), price_currency: "GBP", sold_out: false } }

        it { expect(label).to eq("From £5") }
      end

      context "when the source doesn't say whether it is sold out or what it costs" do
        it "shows no ticket label" do
          expect(page).to have_no_css("[data-icon-name='ticket']")
          expect(page).to have_no_text(I18n.t("events.tickets.sold_out"))
        end
      end

      context "when the event is cancelled" do
        let(:status) { "cancelled" }
        let(:tickets) { { price_from: BigDecimal(5), price_currency: "GBP", sold_out: true } }

        it "leaves the price to the status" do
          expect(page).to have_no_css("[data-icon-name='ticket']")
        end
      end
    end
  end

  describe "on the site card's time line" do
    def time_line(**attrs)
      allow(event).to receive_messages(**attrs) if attrs.any?
      render_inline(Components::Sites::Event.new(event:))
      page.find("[data-part='detail'][data-variant='time']").text.squish
    end

    it("adds Free after the times") { expect(time_line(price_from: BigDecimal(0))).to eq("7pm \u2013 9pm, Free") }
    it("adds the price after the times") { expect(time_line(price_from: BigDecimal(5), price_currency: "GBP")).to eq("7pm \u2013 9pm, From £5") }
    it("says sold out in place of the price") { expect(time_line(price_from: BigDecimal(5), price_currency: "GBP", sold_out: true)).to eq("7pm \u2013 9pm, Sold out") }
    it("adds it after a start time with no end") { expect(time_line(dtend: nil, price_from: BigDecimal(0))).to eq("7pm, Free") }

    it "adds it after a long-running event's dates" do
      Timecop.travel(Time.zone.local(2026, 11, 1)) do
        expect(time_line(dtend: Time.zone.parse("2027-01-17 17:00"), price_from: BigDecimal(0))).to eq("From 19 Nov until 17 Jan 2027, Free")
      end
    end

    it "shows only the times with no ticket data" do
      expect(time_line).to eq("7pm \u2013 9pm")
      expect(page).to have_no_css("[data-variant='tickets'], [data-icon-name='ticket']")
    end

    context "when the event is called off" do
      def struck = page.find("[data-variant='time'] s.line-through").text.squish
      def status_word = page.find("[data-variant='time'] [data-scope='event-status']")

      it "leads with the status, strikes the times and shows no price" do
        expect(time_line(status: "cancelled", price_from: BigDecimal(5), price_currency: "GBP")).to eq("Cancelled, 7pm \u2013 9pm")
        expect(struck).to eq("7pm \u2013 9pm")
        expect(status_word.text).to eq(I18n.t("events.status.cancelled"))
        expect(status_word[:class]).to eq("font-bold")
        expect(page).to have_no_css("[data-variant='time'].line-through, [data-variant='status']")
      end

      it "says postponed" do
        expect(time_line(status: "postponed")).to eq("Postponed, 7pm \u2013 9pm")
      end

      it "strikes a start time with no end" do
        expect(time_line(status: "cancelled", dtend: nil)).to eq("Cancelled, 7pm")
        expect(struck).to eq("7pm")
      end

      it "strikes a long-running event's dates" do
        Timecop.travel(Time.zone.local(2026, 11, 1)) do
          expect(time_line(status: "cancelled", dtend: Time.zone.parse("2027-01-17 17:00"))).to eq("Cancelled, From 19 Nov until 17 Jan 2027")
        end
        expect(struck).to eq("From 19 Nov until 17 Jan 2027")
      end
    end

    it "gives no line of its own to the price" do
      time_line(price_from: BigDecimal(0))
      expect(page).to have_no_css("[data-variant='tickets']")
    end
  end

  describe "on the event page's details line" do
    def summary
      render_inline(Components::Sites::Event.new(event:, display_context: :page))
      page.find("[data-part='detail'][data-variant='tickets']").text.strip
    end

    context "when sold out with a price" do
      let(:tickets) { { price_from: BigDecimal("7.50"), price_currency: "GBP", sold_out: true } }

      it("gives both") { expect(summary).to eq("From £7.50, sold out") }
    end

    context "when sold out with no price" do
      let(:tickets) { { sold_out: true } }

      it { expect(summary).to eq(I18n.t("events.tickets.sold_out")) }
    end

    context "when free" do
      let(:tickets) { { price_from: BigDecimal(0) } }

      it { expect(summary).to eq(I18n.t("events.tickets.free")) }
    end
  end

  describe "price formatting" do
    def label(price, currency)
      allow(event).to receive_messages(price_from: BigDecimal(price), price_currency: currency)
      render_inline(Components::Sites::EventRow.new(event:))
      page.find("[data-variant='tickets']").text.strip
    end

    it("drops the pence from a whole amount") { expect(label("12", "GBP")).to eq("From £12") }
    it("keeps both places of pence") { expect(label("4.5", "GBP")).to eq("From £4.50") }
    it("uses the euro sign") { expect(label("10", "EUR")).to eq("From €10") }
    it("uses the dollar sign") { expect(label("15", "USD")).to eq("From $15") }
    it("puts the code before a currency with no symbol") { expect(label("15", "CHF")).to eq("From CHF 15") }
    it("groups thousands") { expect(label("1250", "GBP")).to eq("From £1,250") }

    it "shows no price for an amount with no currency" do
      allow(event).to receive_messages(price_from: BigDecimal(5), price_currency: nil)
      render_inline(Components::Sites::EventRow.new(event:))
      expect(page).to have_no_css("[data-variant='tickets']")
    end
  end
end
