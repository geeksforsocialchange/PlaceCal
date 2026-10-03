# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::PageActions, type: :component do
  it "renders nothing when there are no links" do
    render_inline(described_class.new(links: []))

    expect(page).not_to have_css("nav.page-actions")
  end

  it "renders one link per entry, labelled from a locale key" do
    render_inline(described_class.new(links: [["Back to events", "/events"], ["Add to calendar", "/events/1.ics"]]))

    expect(page).to have_css("nav.page-actions[aria-label='#{I18n.t('page_actions.label')}']")
    expect(page).to have_link("Back to events", href: "/events", class: "page-actions__link")
    expect(page).to have_link("Add to calendar", href: "/events/1.ics", class: "page-actions__link")
  end

  it "passes extra link options through to the underlying link" do
    render_inline(described_class.new(links: [["Download", "/events/1.ics", { rel: "nofollow" }]]))

    link = page.find_link("Download")
    expect(link[:rel]).to eq("nofollow")
    expect(link[:class]).to eq("page-actions__link")
  end
end
