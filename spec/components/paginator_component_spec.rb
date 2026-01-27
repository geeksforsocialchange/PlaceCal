# frozen_string_literal: true

require "rails_helper"

RSpec.describe PaginatorComponent, type: :component do
  let(:pointer) { Date.new(2024, 1, 15) }

  it "renders paginator structure" do
    render_inline(described_class.new(pointer: pointer, period: "day", show_breadcrumb: false))

    expect(page).to have_css(".paginator")
  end

  context "with day period" do
    it "renders paginator buttons" do
      render_inline(described_class.new(pointer: pointer, period: "day", show_breadcrumb: false))

      expect(page).to have_css(".paginator__buttons")
    end

    it "renders navigation arrows" do
      render_inline(described_class.new(pointer: pointer, period: "day", show_breadcrumb: false))

      expect(page).to have_css(".paginator__arrow--back")
      expect(page).to have_css(".paginator__arrow--forwards")
    end
  end

  context "with week period" do
    it "renders paginator buttons" do
      render_inline(described_class.new(pointer: pointer, period: "week", show_breadcrumb: false))

      expect(page).to have_css(".paginator__buttons")
    end
  end

  context "with future period" do
    it "does not render paginator buttons" do
      render_inline(described_class.new(pointer: pointer, period: "future", show_breadcrumb: false))

      expect(page).not_to have_css(".paginator__buttons")
    end
  end

  describe "#step" do
    it "returns 1 day for day period" do
      component = described_class.new(pointer: pointer, period: "day")
      expect(component.step).to eq(1.day)
    end

    it "returns 1 week for week period" do
      component = described_class.new(pointer: pointer, period: "week")
      expect(component.step).to eq(1.week)
    end
  end

  describe "#sort" do
    it "defaults to time" do
      component = described_class.new(pointer: pointer, period: "day")
      expect(component.sort).to eq("time")
    end

    it "uses provided sort value" do
      component = described_class.new(pointer: pointer, period: "day", sort: "summary")
      expect(component.sort).to eq("summary")
    end
  end

  describe "#path" do
    it "defaults to events" do
      component = described_class.new(pointer: pointer, period: "day")
      expect(component.path).to eq("events")
    end

    it "uses provided path" do
      component = described_class.new(pointer: pointer, period: "day", path: "partners/1/events")
      expect(component.path).to eq("partners/1/events")
    end
  end

  describe "#today?" do
    it "returns true when pointer is today" do
      component = described_class.new(pointer: Time.zone.today, period: "day")
      expect(component.today?).to be true
    end

    it "returns false when pointer is not today" do
      component = described_class.new(pointer: Time.zone.today + 1.day, period: "day")
      expect(component.today?).to be false
    end

    it "returns false when pointer is in the past" do
      component = described_class.new(pointer: Time.zone.today - 1.day, period: "day")
      expect(component.today?).to be false
    end
  end

  describe "#today_url" do
    it "generates URL for today with default path" do
      today = Time.zone.today
      component = described_class.new(pointer: pointer, period: "day", sort: "time")
      expected_url = "/events/#{today.year}/#{today.month}/#{today.day}?period=day&sort=time#paginator"
      expect(component.today_url).to eq(expected_url)
    end

    it "generates URL for today with custom path" do
      today = Time.zone.today
      component = described_class.new(pointer: pointer, period: "week", path: "partners/my-partner/events", sort: "time")
      expected_url = "/partners/my-partner/events/#{today.year}/#{today.month}/#{today.day}?period=week&sort=time#paginator"
      expect(component.today_url).to eq(expected_url)
    end

    it "includes repeating parameter when set" do
      today = Time.zone.today
      component = described_class.new(pointer: pointer, period: "day", sort: "time", repeating: "off")
      expected_url = "/events/#{today.year}/#{today.month}/#{today.day}?period=day&sort=time&repeating=off#paginator"
      expect(component.today_url).to eq(expected_url)
    end
  end

  describe "#window_start" do
    let(:today) { Time.zone.today }

    context "when pointer is today" do
      it "returns today" do
        component = described_class.new(pointer: today, period: "day")
        expect(component.window_start).to eq(today)
      end
    end

    context "when pointer is before today" do
      it "returns the pointer date" do
        past_date = today - 5.days
        component = described_class.new(pointer: past_date, period: "day")
        expect(component.window_start).to eq(past_date)
      end
    end

    context "when pointer is close to today (within center offset)" do
      it "keeps today on the left for day period" do
        # Default steps is 7, so center_offset is 3
        # When pointer is within 3 days of today, today stays on left
        close_date = today + 2.days
        component = described_class.new(pointer: close_date, period: "day")
        expect(component.window_start).to eq(today)
      end

      it "keeps today on the left for week period" do
        # For week period, center_offset is 3 weeks
        close_date = today + 2.weeks
        component = described_class.new(pointer: close_date, period: "week")
        expect(component.window_start).to eq(today)
      end
    end

    context "when pointer is far from today" do
      it "centers the selection in the window for day period" do
        # Default steps is 7, so center_offset is 3
        # When pointer is more than 3 days from today, it gets centered
        far_date = today + 10.days
        component = described_class.new(pointer: far_date, period: "day")
        # window_start should be pointer - (center_offset * step)
        # = far_date - (3 * 1.day) = far_date - 3.days
        expect(component.window_start).to eq(far_date - 3.days)
      end

      it "centers the selection in the window for week period" do
        far_date = today + 10.weeks
        component = described_class.new(pointer: far_date, period: "week")
        # window_start should be pointer - (center_offset * step)
        # = far_date - (3 * 1.week) = far_date - 3.weeks
        expect(component.window_start).to eq(far_date - 3.weeks)
      end
    end
  end

  describe "Today button rendering in actions" do
    context "when pointer is today" do
      it "does not render Today link in actions" do
        render_inline(described_class.new(pointer: Time.zone.today, period: "day", show_breadcrumb: false))
        expect(page).not_to have_css(".paginator__actions .breadcrumb__today")
      end
    end

    context "when pointer is not today" do
      it "renders Today link in actions" do
        render_inline(described_class.new(pointer: Time.zone.today + 5.days, period: "day", show_breadcrumb: false))
        expect(page).to have_css(".paginator__actions .breadcrumb__today", text: "Today")
      end
    end
  end
end
