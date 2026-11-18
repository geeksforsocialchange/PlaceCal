# frozen_string_literal: true

require "rails_helper"

# Specs run on 8 Nov 2022.
RSpec.describe "Long-running events", type: :request do
  let(:site) { create(:site, slug: "test-site") }
  let(:ward) { create(:riverside_ward) }
  let(:partner) { create(:riverside_partner, address: create(:riverside_address, neighbourhood: ward)) }
  let(:host) { "#{site.slug}.lvh.me" }

  let!(:on_now) do
    create(:event, organiser: partner, summary: "Dead or Alive",
                   dtstart: Time.zone.local(2022, 10, 1, 10), dtend: Time.zone.local(2023, 1, 17, 17))
  end
  let!(:opens_later) do
    create(:event, organiser: partner, summary: "Magic Place",
                   dtstart: Time.zone.local(2022, 11, 28, 10), dtend: Time.zone.local(2023, 1, 17, 17))
  end
  let!(:ended) do
    create(:event, organiser: partner, summary: "Highlights Tours",
                   dtstart: Time.zone.local(2022, 9, 1, 10), dtend: Time.zone.local(2022, 11, 7, 17))
  end
  let!(:short) do
    create(:event, organiser: partner, summary: "Winter Collages",
                   dtstart: Time.zone.local(2022, 11, 10, 10), dtend: Time.zone.local(2022, 11, 13, 10))
  end

  before { site.neighbourhoods << ward }

  def frame
    Capybara.string(response.body[%r{<turbo-frame[^>]*id="events-browser"[^>]*>.*?</turbo-frame>}m])
  end

  def titles
    frame.all("a.p-name").map(&:text)
  end

  describe "the main events listing" do
    it "lists a long-running event once, on its start day, until its end date" do
      get events_url(host:, period: "future")

      expect(titles).to eq(["Winter Collages", "Magic Place"])
      row = frame.find(".h-event", text: "Magic Place")
      expect(row).to have_text("From 28 Nov until 17 Jan 2023")
      expect(row).to have_css("time.dt-start[datetime^='2022-11-28']")
      expect(frame).to have_text("2 events")
    end

    it "leaves events of 3 days or less showing their times" do
      get events_url(host:, period: "future")

      row = frame.find(".h-event", text: "Winter Collages")
      expect(row).to have_text("10am – 10am")
      expect(row).to have_no_text("Until")
    end

    it "hides long-running events, or shows only them" do
      get events_url(host:, period: "future", long_running: "off")
      expect(titles).to eq(["Winter Collages"])

      get events_url(host:, period: "future", long_running: "only")
      expect(titles).to eq(["Magic Place"])
    end

    it "keeps the filter in the timeline and the filter panel" do
      get events_url(host:, period: "week", long_running: "off")

      expect(frame.all("[data-scope='timeline'] a").map { it[:href] }).to all(include("long_running=off"))
      expect(frame).to have_css("input[type='radio'][name='long_running'][value='off'][checked]")
      expect(frame).to have_css("input[type='hidden'][name='long_running'][value='off']", visible: :all)
    end

    it "strikes through the From and until line of a called-off event" do
      opens_later.update!(status: "cancelled")
      get events_url(host:, period: "future")

      expect(frame.find(".h-event", text: "Magic Place")).to have_css(".line-through", text: "From 28 Nov until 17 Jan 2023")
    end
  end

  describe "a partner's events listing" do
    it "lists a running event once at the top, and drops ended ones" do
      get partner_url(partner, host:)

      expect(titles).to eq(["Dead or Alive", "Winter Collages", "Magic Place"])
      expect(frame.find(".h-event", text: "Dead or Alive")).to have_text("From 1 Oct until 17 Jan 2023")
    end

    it "offers the long-running select only to a partner with long-running events, or once one is chosen" do
      long_running_select = "select[name='long_running']"
      get partner_url(partner, host:)
      expect(Capybara.string(response.body)).to have_css(long_running_select)

      other = create(:partner, address: create(:riverside_address, neighbourhood: ward))
      create(:event, organiser: other, dtstart: 2.days.from_now, dtend: 2.days.from_now + 2.hours)
      get partner_url(other, host:)
      expect(Capybara.string(response.body)).to have_css("select[name='repeating']")
      expect(Capybara.string(response.body)).to have_no_css(long_running_select)

      get partner_url(other, host:, params: { long_running: "off" })
      expect(Capybara.string(response.body)).to have_css(long_running_select)
    end

    it "counts running events as on today" do
      get partner_url(partner, host:)

      expect(frame).to have_text("3 events across 3 days")
    end

    it "applies the long-running filter to running events too" do
      get partner_url(partner, host:, params: { long_running: "off" })
      expect(titles).to eq(["Winter Collages"])

      get partner_url(partner, host:, params: { long_running: "only" })
      expect(titles).to eq(["Dead or Alive", "Magic Place"])
    end

    it "offers the long-running select and keeps it in the show-more link" do
      get partner_url(partner, host:, params: { long_running: "on", days: 1 })

      expect(frame).to have_select("Long-running events", selected: "Show long-running events")
      expect(frame.find_link("Show 1 more day")[:href]).to include("long_running=on")
    end

    it "lists an event starting today once, in the day's list" do
      Timecop.freeze(Time.zone.local(2022, 11, 28, 12)) { get partner_url(partner, host:) }

      expect(titles).to eq(["Dead or Alive", "Magic Place"])
    end

    context "when its only event is a running exhibition" do
      before { [opens_later, ended, short].each(&:destroy) }

      it "lists it rather than saying there are no upcoming events" do
        get partner_url(partner, host:)

        expect(titles).to eq(["Dead or Alive"])
        expect(response.body).not_to include("no upcoming events")
        expect(frame).to have_text("1 event across 1 day")
      end
    end

    context "after it ends" do
      before do
        [opens_later, short].each(&:destroy)
        create(:calendar, organiser: partner)
      end

      it "says there are no upcoming events" do
        on_now.update!(dtend: Time.zone.local(2022, 11, 7, 17))
        get partner_url(partner, host:)

        expect(response.body).to include("This partner has no upcoming events.")
      end
    end

    context "with enough events to page through" do
      before do
        31.times do |i|
          create(:event, organiser: partner, dtstart: (i + 1).days.from_now.change(hour: 9), dtend: (i + 1).days.from_now.change(hour: 10))
        end
      end

      it "keeps the paginator on a later week, with the events running then above the week" do
        get "/partners/#{partner.slug}/events/2022/12/5", params: { period: "week" }, headers: { host: }

        expect(frame).to have_css("[data-scope='timeline'][data-part='root']")
        expect(titles.first).to eq("Dead or Alive")
        expect(titles).to include("Magic Place").once
      end
    end

    it "lists a running event at the top on the directory too" do
      get partner_url(partner, host: "lvh.me")

      summaries = Capybara.string(response.body).all("a[href^='/events/']").map(&:text) & [on_now, opens_later, short, ended].map(&:summary)
      expect(summaries).to eq(["Dead or Alive", "Winter Collages", "Magic Place"])
      expect(response.body).to include("From 1 Oct until 17 Jan 2023")
    end
  end

  describe "upcoming counts" do
    it "counts running and future events, not ended ones" do
      expect(EventsQuery.upcoming_counts_by_partner([partner.id])).to eq(partner.id => 3)
    end
  end

  describe "the event page" do
    it "shows the date range in place of a time range on a site" do
      get event_url(on_now, host:)
      details = Capybara.string(response.body).find("[data-scope='event'][data-part='details']")

      expect(details).to have_css("[data-variant='date']", text: "1 Oct to 17 Jan 2023")
      expect(details).to have_no_css("[data-variant='time']")
    end

    it "shows the date range in place of a time range on the directory" do
      get event_url(on_now, host: "lvh.me")
      html = Capybara.string(response.body).find("main")

      expect(html).to have_text("1 Oct to 17 Jan 2023", count: 2)
      expect(html).to have_no_text("10:00 – 17:00")
    end

    it "keeps the time range for events of 3 days or less" do
      get event_url(short, host:)
      details = Capybara.string(response.body).find("[data-scope='event'][data-part='details']")

      expect(details).to have_css("[data-variant='time']", text: "10am – 13 Nov 10am")
    end
  end
end
