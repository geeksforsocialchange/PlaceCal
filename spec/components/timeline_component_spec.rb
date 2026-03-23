# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Timeline, type: :component do
  # Tests run with time frozen at 2022-11-08 (Tuesday)
  let(:today) { Date.new(2022, 11, 8) }

  let(:base_attrs) do
    {
      pointer: today,
      period: "day",
      sort: "time",
      repeating: "on",
      path: "events"
    }
  end

  describe "rendering" do
    context "with day period" do
      it "renders timeline buttons" do
        render_inline(described_class.new(**base_attrs))

        expect(page).to have_css("ol.paginator__buttons")
      end

      it "renders navigation arrows" do
        render_inline(described_class.new(**base_attrs))

        expect(page).to have_css(".paginator__arrow--back")
        expect(page).to have_css(".paginator__arrow--forwards")
      end

      it "renders day buttons with correct count" do
        render_inline(described_class.new(**base_attrs))

        # 7 day buttons plus 2 arrows
        expect(page).to have_css("li", count: 9)
      end

      it "marks current date as active" do
        render_inline(described_class.new(**base_attrs))

        expect(page).to have_css("li.active")
      end

      it "shows Today label for current date" do
        render_inline(described_class.new(**base_attrs))

        expect(page).to have_text("Today")
      end

      it "shows Tomorrow label for next day" do
        render_inline(described_class.new(**base_attrs))

        expect(page).to have_text("Tomorrow")
      end
    end

    context "with week period" do
      let(:attrs) { base_attrs.merge(period: "week") }

      it "renders timeline buttons" do
        render_inline(described_class.new(**attrs))

        expect(page).to have_css("ol.paginator__buttons")
      end

      it "shows Next 7 days for current week" do
        render_inline(described_class.new(**attrs))

        expect(page).to have_text("Next 7 days")
      end

      it "shows date ranges for other weeks" do
        render_inline(described_class.new(**attrs))

        # Should show date range format like "15 - 21 Nov"
        expect(page).to have_text(/\d+ - \d+ \w+/)
      end
    end

    context "with month period" do
      let(:attrs) { base_attrs.merge(period: "month") }

      it "renders timeline buttons" do
        render_inline(described_class.new(**attrs))

        expect(page).to have_css("ol.paginator__buttons--month")
      end

      it "shows This month for current month" do
        render_inline(described_class.new(**attrs))

        expect(page).to have_text("This month")
      end

      it "shows abbreviated month names for other months" do
        render_inline(described_class.new(**attrs))

        expect(page).to have_text("Dec")
        expect(page).to have_text("Jan")
      end

      it "marks current month as active" do
        render_inline(described_class.new(**attrs))

        expect(page).to have_css("li.active", text: "This month")
      end

      it "generates URLs with month period" do
        render_inline(described_class.new(**attrs))

        expect(page).to have_link(href: %r{/events/\d+/\d+/\d+\?period=month&sort=time&repeating=on#paginator})
      end
    end

    context "with month period pointing to a future month" do
      let(:future_month) { Date.new(2023, 3, 1) }
      let(:attrs) { base_attrs.merge(period: "month", pointer: future_month) }

      it "shows abbreviated month name for non-current months" do
        render_inline(described_class.new(**attrs))

        expect(page).to have_css("li.active", text: "Mar")
      end
    end

    context "with upcoming period and show_upcoming" do
      let(:attrs) { base_attrs.merge(period: "upcoming", show_upcoming: true) }

      it "renders timeline with Upcoming tab" do
        render_inline(described_class.new(**attrs))

        expect(page).to have_css("ol.paginator__buttons")
        expect(page).to have_text("Upcoming")
      end

      it "marks Upcoming as active" do
        render_inline(described_class.new(**attrs))

        expect(page).to have_css("li.active", text: "Upcoming")
      end

      it "shows month tabs alongside Upcoming" do
        render_inline(described_class.new(**attrs))

        expect(page).to have_text("This month")
      end

      it "generates upcoming URL with period=upcoming" do
        render_inline(described_class.new(**attrs))

        expect(page).to have_link("Upcoming", href: /period=upcoming/)
      end

      it "generates month URLs with period=month" do
        render_inline(described_class.new(**attrs))

        expect(page).to have_link("This month", href: /period=month/)
      end
    end

    context "with month period and show_upcoming" do
      let(:attrs) { base_attrs.merge(period: "month", show_upcoming: true) }

      it "shows Upcoming tab as inactive" do
        render_inline(described_class.new(**attrs))

        upcoming_li = page.find("li", text: "Upcoming")
        expect(upcoming_li[:class]).not_to include("active")
      end

      it "marks This month as active" do
        render_inline(described_class.new(**attrs))

        expect(page).to have_css("li.active", text: "This month")
      end
    end

    context "with future period" do
      let(:attrs) { base_attrs.merge(period: "future") }

      it "does not render" do
        render_inline(described_class.new(**attrs))

        expect(page).not_to have_css("ol.paginator__buttons")
      end
    end
  end

  describe "URL generation" do
    it "generates correct URLs with all params" do
      render_inline(described_class.new(**base_attrs))

      expect(page).to have_link(href: %r{/events/2022/11/\d+\?period=day&sort=time&repeating=on#paginator})
    end

    context "with custom path" do
      let(:attrs) { base_attrs.merge(path: "partners/test-partner/events") }

      it "uses custom path in URLs" do
        render_inline(described_class.new(**attrs))

        expect(page).to have_link(href: %r{/partners/test-partner/events/2022/11/\d+})
      end
    end
  end

  describe "pointer handling" do
    context "when pointer is a string" do
      let(:attrs) { base_attrs.merge(pointer: "2022-11-08") }

      it "parses string dates" do
        expect { render_inline(described_class.new(**attrs)) }.not_to raise_error
        expect(page).to have_css("ol.paginator__buttons")
      end
    end

    context "when pointer is in the future" do
      let(:future_date) { today + 30.days }
      let(:attrs) { base_attrs.merge(pointer: future_date) }

      it "renders with future date as active" do
        render_inline(described_class.new(**attrs))

        expect(page).to have_css("li.active")
      end
    end
  end
end
