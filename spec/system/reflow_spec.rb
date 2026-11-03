# frozen_string_literal: true

require "rails_helper"

# WCAG 1.4.10: at 320 CSS pixels wide, content reflows into one column with no sideways scrolling.
RSpec.describe "Reflow at 320px", :slow, type: :system do
  include_context "normal island data"

  let(:site) { create(:site, slug: "riverside") }

  before do
    create(:sites_neighbourhood, site:, neighbourhood: riverside_hub.address.neighbourhood, relation_type: "Primary")
    page.current_window.resize_to(320, 640)
  end

  def page_width
    page.evaluate_script("document.documentElement.scrollWidth")
  end

  {
    "the directory homepage" => -> { public_url("/") },
    "the directory events listing" => -> { public_url("/events") },
    "the directory partnerships listing" => -> { public_url("/partnerships") },
    "our story" => -> { public_url("/our-story") },
    "the get in touch form" => -> { public_url("/get-in-touch") },
    "the join pricing page" => -> { join_url("/pricing") },
    "the book a demo form" => -> { join_url("/book-a-demo") },
    "a site's partners listing" => -> { "http://riverside.lvh.me:#{Capybara.current_session.server.port}/partners" }
  }.each do |name, url|
    it "does not scroll sideways on #{name}" do
      visit instance_exec(&url)

      expect(page_width).to be <= 320
    end
  end

  it "does not scroll sideways with a site's menu open" do
    visit "http://riverside.lvh.me:#{Capybara.current_session.server.port}/"
    find("[data-scope='navigation'][data-part='toggle']").click

    expect(page).to have_css("[data-scope='navigation'][data-part='menu'] a", visible: :visible)
    expect(page_width).to be <= 320
  end
end
