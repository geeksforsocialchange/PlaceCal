# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin layout", type: :request do
  let(:root_user) { create(:root_user) }
  let(:document) { Nokogiri::HTML(response.body) }

  before do
    sign_in root_user
    get "http://#{admin_host}/partners"
  end

  it "starts with a skip link to the main content" do
    first_focusable = document.at_css("body a[href], body button, body input, body select, body textarea, body [tabindex]:not([tabindex='-1'])")

    expect(first_focusable["href"]).to eq("#main-content")
    expect(first_focusable.text).to eq(I18n.t("navigation.skip_to_content"))
  end

  it "lets the main element take focus" do
    expect(document.at_css("main#main-content")["tabindex"]).to eq("-1")
  end

  it "has a menu button that controls the sidebar" do
    toggle = document.at_css("header button[aria-controls='admin-sidebar']")

    expect(toggle["aria-expanded"]).to eq("false")
    expect(toggle.text.strip).to eq(I18n.t("admin.topbar.menu"))
    expect(document.at_css("nav#admin-sidebar")["aria-label"]).to eq(I18n.t("admin.leftbar.label"))
  end

  it "marks the current page in the sidebar" do
    current = document.css("#admin-sidebar a[aria-current='page']")

    expect(current.map { |link| link.text.strip }).to eq([Partner.model_name.human(count: 2)])
  end

  it "gives the sidebar sections h2 headings and no nested navigation" do
    expect(document.css("#admin-sidebar h2").map(&:text)).to include(I18n.t("admin.leftbar.content_types"))
    expect(document.css("#admin-sidebar h6, #admin-sidebar nav")).to be_empty
  end
end
