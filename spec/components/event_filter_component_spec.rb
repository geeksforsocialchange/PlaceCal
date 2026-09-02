# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::EventFilter, type: :component do
  # Tests run with time frozen at 2022-11-08 (Tuesday)
  let(:today) { Date.new(2022, 11, 8) }

  let(:base_attrs) do
    {
      pointer: today,
      period: "day",
      sort: "time",
      repeating: "on",
      today_url: "/events/2022/11/8?period=day&sort=time&repeating=on#paginator",
      today: false
    }
  end

  describe "Today link" do
    context "when not on today" do
      it "renders Today link" do
        render_inline(described_class.new(**base_attrs))

        expect(page).to have_link("Today", href: base_attrs[:today_url])
      end

      it "applies correct styling class" do
        render_inline(described_class.new(**base_attrs))

        expect(page).to have_css("a.filters__link--today")
      end
    end

    context "when on today" do
      let(:attrs) { base_attrs.merge(today: true) }

      it "does not render Today link" do
        render_inline(described_class.new(**attrs))

        expect(page).not_to have_link("Today")
      end
    end
  end

  describe "Go to date picker" do
    it "renders Go to date button" do
      render_inline(described_class.new(**base_attrs))

      expect(page).to have_button("Go to date")
    end

    it "renders with down arrow icon" do
      render_inline(described_class.new(**base_attrs))

      expect(page).to have_selector('svg[data-icon-name="triangle_down"]')
    end

    it "renders hidden date input" do
      render_inline(described_class.new(**base_attrs))

      expect(page).to have_css("input[type='date'].filters__date-input", visible: :all)
    end

    it "sets date input value to pointer" do
      render_inline(described_class.new(**base_attrs))

      expect(page).to have_css("input[type='date'][value='#{today}']", visible: :all)
    end

    it "connects to date-picker Stimulus controller" do
      render_inline(described_class.new(**base_attrs))

      expect(page).to have_css("[data-controller='date-picker']")
    end
  end

  describe "hidden form fields" do
    it "includes period hidden field" do
      render_inline(described_class.new(**base_attrs))

      expect(page).to have_css("input[type='hidden'][name='period'][value='day']", visible: :all)
    end

    it "includes sort hidden field" do
      render_inline(described_class.new(**base_attrs))

      expect(page).to have_css("input[type='hidden'][name='sort'][value='time']", visible: :all)
    end

    it "includes repeating hidden field" do
      render_inline(described_class.new(**base_attrs))

      expect(page).to have_css("input[type='hidden'][name='repeating'][value='on']", visible: :all)
    end
  end

  describe "filter dropdown" do
    it "renders Filter and sort toggle" do
      render_inline(described_class.new(**base_attrs))

      expect(page).to have_button("Filter and sort")
    end

    it "connects to filters Stimulus controller" do
      render_inline(described_class.new(**base_attrs))

      expect(page).to have_css("[data-controller~='filters']")
    end

    describe "sort options" do
      it "renders Sort by date option" do
        render_inline(described_class.new(**base_attrs))

        expect(page).to have_field("sort_time", type: "radio")
        expect(page).to have_text("Sort by date")
      end

      it "renders Sort by name option" do
        render_inline(described_class.new(**base_attrs))

        expect(page).to have_field("sort_summary", type: "radio")
        expect(page).to have_text("Sort by name")
      end

      it "checks current sort option" do
        render_inline(described_class.new(**base_attrs))

        expect(page).to have_checked_field("sort_time")
      end
    end

    describe "period options" do
      it "renders Daily view option" do
        render_inline(described_class.new(**base_attrs))

        expect(page).to have_field("period_day", type: "radio")
        expect(page).to have_text("Daily view")
      end

      it "renders Weekly view option" do
        render_inline(described_class.new(**base_attrs))

        expect(page).to have_field("period_week", type: "radio")
        expect(page).to have_text("Weekly view")
      end

      it "renders Show all option" do
        render_inline(described_class.new(**base_attrs))

        expect(page).to have_field("period_future", type: "radio")
        expect(page).to have_text("Show all")
      end

      it "checks current period option" do
        render_inline(described_class.new(**base_attrs))

        expect(page).to have_checked_field("period_day")
      end
    end

    describe "repeating options" do
      it "renders Show repeats option" do
        render_inline(described_class.new(**base_attrs))

        expect(page).to have_field("repeating_on", type: "radio")
        expect(page).to have_text("Show repeats")
      end

      it "renders Show repeats last option" do
        render_inline(described_class.new(**base_attrs))

        expect(page).to have_field("repeating_last", type: "radio")
        expect(page).to have_text("Show repeats last")
      end

      it "renders Hide repeats option" do
        render_inline(described_class.new(**base_attrs))

        expect(page).to have_field("repeating_off", type: "radio")
        expect(page).to have_text("Hide repeats")
      end

      it "checks current repeating option" do
        render_inline(described_class.new(**base_attrs))

        expect(page).to have_checked_field("repeating_on")
      end
    end
  end

  describe "monthly view option" do
    context "when show_monthly is true (default)" do
      it "renders Monthly view option" do
        render_inline(described_class.new(**base_attrs))

        expect(page).to have_field("period_month", type: "radio")
        expect(page).to have_text("Monthly view")
      end
    end

    context "when show_monthly is false" do
      let(:attrs) { base_attrs.merge(show_monthly: false) }

      it "does not render Monthly view option" do
        render_inline(described_class.new(**attrs))

        expect(page).not_to have_field("period_month", type: "radio")
        expect(page).not_to have_text("Monthly view")
      end

      it "still renders other period options" do
        render_inline(described_class.new(**attrs))

        expect(page).to have_field("period_day", type: "radio")
        expect(page).to have_field("period_week", type: "radio")
        expect(page).to have_field("period_future", type: "radio")
      end
    end
  end

  describe "neighbourhood filter" do
    let(:district) { create(:neighbourhood, name: "Test District", unit: "district") }
    let(:future_attrs) { base_attrs.merge(period: "future") }
    let(:ward1) { create(:neighbourhood, name: "Hillcrest", unit: "ward", parent: district) }
    let(:ward2) { create(:neighbourhood, name: "Valleyview", unit: "ward", parent: district) }
    let(:site) do
      s = create(:site)
      create(:sites_neighbourhood, site: s, neighbourhood: district)
      s
    end
    let(:address1) { create(:address, neighbourhood: ward1) }
    let(:address2) { create(:address, neighbourhood: ward2) }
    let(:partner1) do
      p = create(:partner, address: address1)
      p.service_areas << create(:service_area, neighbourhood: ward1)
      p
    end
    let(:partner2) do
      p = create(:partner, address: address2)
      p.service_areas << create(:service_area, neighbourhood: ward2)
      p
    end

    before do
      create_list(:future_event, 3, organiser: partner1, address: address1)
      create_list(:future_event, 2, organiser: partner2, address: address2)
    end

    it "shows neighbourhood filter when multiple neighbourhoods have events" do
      render_inline(described_class.new(**future_attrs, site: site))

      expect(page).to have_selector("button span.filters__link", text: "Neighbourhood")
    end

    it "shows selected neighbourhood name when a neighbourhood is selected" do
      render_inline(described_class.new(**future_attrs, site: site, selected_neighbourhood: ward1.id.to_s))

      expect(page).to have_selector("button span.filters__link", text: ward1.name)
    end

    it "does not show neighbourhood filter when only one neighbourhood has events" do
      other_district = create(:neighbourhood, name: "Other District", unit: "district")
      single_ward = create(:neighbourhood, name: "Only Ward", unit: "ward", parent: other_district)
      single_address = create(:address, neighbourhood: single_ward)
      single_partner = create(:partner, address: single_address)
      single_partner.service_areas << create(:service_area, neighbourhood: single_ward)

      single_site = create(:site)
      create(:sites_neighbourhood, site: single_site, neighbourhood: other_district)

      create_list(:future_event, 3, organiser: single_partner, address: single_address)

      render_inline(described_class.new(**future_attrs, site: single_site))

      expect(page).not_to have_selector("button span.filters__link", text: "Neighbourhood")
    end
  end

  describe "day strip filter style (D22)" do
    let(:day_strip_attrs) { base_attrs.merge(filter_style: :day_strip) }

    it "does not render the date picker chrome" do
      render_inline(described_class.new(**day_strip_attrs))

      expect(page).not_to have_button("Go to date")
      expect(page).not_to have_css("[data-controller='date-picker']")
    end

    it "renders seven day links plus All upcoming" do
      render_inline(described_class.new(**day_strip_attrs))

      expect(page).to have_css("nav.day-strip a", count: 8)
      expect(page).to have_link("Today")
      expect(page).to have_link("Tomorrow")
      expect(page).to have_link("All upcoming")
    end

    it "labels the remaining days with weekday and day number" do
      render_inline(described_class.new(**day_strip_attrs))

      expect(page).to have_link("Thu 10")
      expect(page).to have_link("Mon 14")
    end

    it "links each day to its dated events URL" do
      render_inline(described_class.new(**day_strip_attrs))

      expect(page).to have_link("Today", href: "/events/2022/11/8?period=day#paginator")
      expect(page).to have_link("Tomorrow", href: "/events/2022/11/9?period=day#paginator")
      expect(page).to have_link("All upcoming", href: "/events?period=future#paginator")
    end

    it "carries non-default sort and repeating in the links" do
      render_inline(described_class.new(**day_strip_attrs, sort: "summary", repeating: "off"))

      expect(page).to have_link("Today", href: "/events/2022/11/8?period=day&repeating=off&sort=summary#paginator")
      expect(page).to have_link("All upcoming", href: "/events?period=future&repeating=off&sort=summary#paginator")
    end

    it "highlights the current day" do
      render_inline(described_class.new(**day_strip_attrs))

      expect(page).to have_css("a[aria-current='date']", count: 1)
      expect(page).to have_css("a[aria-current='date']", text: "Today")
    end

    it "highlights a navigated day rather than today" do
      render_inline(described_class.new(**day_strip_attrs, pointer: today + 2))

      expect(page).to have_css("a[aria-current='date']", text: "Thu 10")
      expect(page).not_to have_css("a[aria-current='date']", text: "Today")
    end

    it "highlights All upcoming when the period is future" do
      render_inline(described_class.new(**day_strip_attrs, period: "future"))

      expect(page).not_to have_css("a[aria-current='date']")
      expect(page).to have_css("a[aria-current='true']", text: "All upcoming")
    end

    it "keeps the sort and repeating filters" do
      render_inline(described_class.new(**day_strip_attrs))

      expect(page).to have_button("Filter and sort")
      expect(page).to have_field("repeating_on", type: "radio")
    end

    it "scrolls horizontally on narrow viewports" do
      render_inline(described_class.new(**day_strip_attrs))

      expect(page).to have_css("nav.day-strip.overflow-x-auto ul.whitespace-nowrap")
    end
  end

  describe "date picker filter style" do
    it "is the default when no theme asks for the day strip" do
      render_inline(described_class.new(**base_attrs))

      expect(page).not_to have_css("nav.day-strip")
      expect(page).to have_button("Go to date")
    end
  end

  describe "with different parameter values" do
    context "with week period" do
      let(:attrs) { base_attrs.merge(period: "week") }

      it "checks weekly view option" do
        render_inline(described_class.new(**attrs))

        expect(page).to have_checked_field("period_week")
      end
    end

    context "with summary sort" do
      let(:attrs) { base_attrs.merge(sort: "summary") }

      it "checks sort by name option" do
        render_inline(described_class.new(**attrs))

        expect(page).to have_checked_field("sort_summary")
      end
    end

    context "with repeating off" do
      let(:attrs) { base_attrs.merge(repeating: "off") }

      it "checks hide repeats option" do
        render_inline(described_class.new(**attrs))

        expect(page).to have_checked_field("repeating_off")
      end
    end
  end

  describe "region filter" do
    let(:north) { create(:partnership, name: "North") }
    let(:south) { create(:partnership, name: "South") }

    it "is hidden when the site has one partnership tag" do
      render_inline(described_class.new(**base_attrs, region_tags: [north]))

      expect(page).not_to have_css("nav.region-filter")
    end

    it "is shown when the site has two partnership tags" do
      render_inline(described_class.new(**base_attrs, region_tags: [north, south]))

      expect(page).to have_css("nav.region-filter")
      expect(page).to have_link("North")
    end

    it "carries the selected region through the filter forms" do
      render_inline(described_class.new(**base_attrs, region_tags: [north, south], selected_region: north))

      expect(page).to have_css("input[type=hidden][name=region][value='#{north.slug}']", visible: :all)
    end

    it "adds no region field when no region is selected" do
      render_inline(described_class.new(**base_attrs, region_tags: [north, south]))

      expect(page).to have_no_css("input[name=region]", visible: :all)
    end
  end
end
