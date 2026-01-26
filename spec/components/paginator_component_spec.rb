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
end
