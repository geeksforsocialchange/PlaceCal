# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public site logo", type: :request do
  let(:site) { create(:site, slug: "logosite") }
  let(:logo_dir) { Rails.public_path.join("uploads/site/logo/#{site.id}") }
  let(:payload) do
    '<svg xmlns="http://www.w3.org/2000/svg" xmlns:h="http://www.w3.org/1999/xhtml">' \
      '<?x ><img id="probe" src="x">?><h:script id="probe-script">document.title = 1</h:script>' \
      '<rect width="1" height="1"/></svg>'
  end

  # Written straight to disk to stand in for a logo stored before uploads were sanitised this strictly.
  before do
    FileUtils.mkdir_p(logo_dir)
    File.write(logo_dir.join("logo.svg"), payload)
    site.update_column(:logo, "logo.svg") # rubocop:disable Rails/SkipsModelValidations
  end

  after { FileUtils.rm_rf(logo_dir) }

  it "shows an uploaded SVG logo as an image, so nothing in the file becomes part of the page" do
    get "http://logosite.lvh.me"

    expect(response).to be_successful
    page = Nokogiri::HTML5(response.body)
    expect(page.css("#probe, #probe-script")).to be_empty
    expect(page.at_css(".header__branding img")["src"]).to eq("/uploads/site/logo/#{site.id}/logo.svg")
    expect(page.at_css(".header__branding img")["alt"]).to eq(site.name)
  end

  it "serves the uploaded SVG with headers that stop it running script when opened directly" do
    get "http://logosite.lvh.me/uploads/site/logo/#{site.id}/logo.svg"

    expect(response).to be_successful
    expect(response.headers["content-security-policy"]).to include("sandbox", "default-src 'none'")
    expect(response.headers["x-content-type-options"]).to eq("nosniff")
  end
end
