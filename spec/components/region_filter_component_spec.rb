# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::RegionFilter, type: :component do
  let(:north) { create(:partnership, name: "North") }
  let(:south) { create(:partnership, name: "South") }

  it "renders nothing when the site has one tag" do
    render_inline(described_class.new(tags: [north]))

    expect(page).not_to have_css("nav.region-filter")
  end

  it "renders nothing when the site has no tags" do
    render_inline(described_class.new(tags: []))

    expect(page).not_to have_css("nav.region-filter")
  end

  describe "with two tags" do
    it "renders an All option plus one link per tag" do
      render_inline(described_class.new(tags: [north, south]))

      expect(page).to have_css("nav.region-filter")
      expect(page).to have_link("All")
      expect(page).to have_link("North")
      expect(page).to have_link("South")
    end

    it "links each tag by its slug" do
      render_inline(described_class.new(tags: [north, south]))

      expect(page).to have_link("North", href: "/?region=#{north.slug}")
    end

    it "links All back to the unfiltered path" do
      render_inline(described_class.new(tags: [north, south], selected: north))

      expect(page).to have_link("All", href: "/")
    end

    it "marks All as current when nothing is selected" do
      render_inline(described_class.new(tags: [north, south]))

      expect(page).to have_css('a[aria-current="page"]', text: "All")
    end

    it "marks the selected tag as current" do
      render_inline(described_class.new(tags: [north, south], selected: south))

      expect(page).to have_css('a[aria-current="page"]', text: "South")
      expect(page).to have_no_css('a[aria-current="page"]', text: "All")
    end

    it "labels the control from a locale key" do
      render_inline(described_class.new(tags: [north, south]))

      expect(page).to have_css("nav[aria-label='#{I18n.t('region_filter.label')}']")
    end
  end
end
