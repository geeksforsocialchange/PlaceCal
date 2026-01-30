# frozen_string_literal: true

require "rails_helper"

RSpec.describe EventFilterComponent, type: :component do
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

      expect(page).to have_css(".icon--arrow-down")
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
end
