# frozen_string_literal: true

require "rails_helper"

RSpec.describe Site, "SVG logo upload", type: :model do
  let(:site) { create(:site) }
  let(:store_dir) { Rails.public_path.join("uploads/site/logo/#{site.id}") }
  let(:upload_dir) { Dir.mktmpdir }

  def svg_upload(content)
    path = File.join(upload_dir, "logo.svg")
    File.binwrite(path, content)
    Rack::Test::UploadedFile.new(path, "image/svg+xml")
  end

  after do
    FileUtils.rm_rf(store_dir)
    FileUtils.rm_rf(upload_dir)
  end

  it "rejects a file named .svg that is not an SVG, and stores nothing" do
    png = file_fixture("test-image.png").binread

    expect(site.update(logo: svg_upload(png))).to be(false)
    expect(site.errors[:logo]).to include(I18n.t("activerecord.errors.messages.invalid_svg"))
    expect(site.reload.logo.url).to be_nil
    expect(store_dir).not_to exist
  end

  it "rejects an SVG that is not well-formed, and stores nothing" do
    expect(site.update(logo: svg_upload('<svg xmlns="http://www.w3.org/2000/svg"><rect width="1"'))).to be(false)
    expect(site.errors[:logo]).to include(I18n.t("activerecord.errors.messages.invalid_svg"))
    expect(site.reload.logo.url).to be_nil
    expect(store_dir).not_to exist
  end

  it "saves a valid SVG" do
    svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1"><rect width="1" height="1"/></svg>'

    expect(site.update(logo: svg_upload(svg))).to be(true)
    expect(site.reload.logo.url).to eq("/uploads/site/logo/#{site.id}/logo.svg")
    expect(File.read(site.logo.path)).to include("<rect")
  end
end
