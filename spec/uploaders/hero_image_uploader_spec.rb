# frozen_string_literal: true

require "rails_helper"

RSpec.describe HeroImageUploader do
  it "makes WebP copies at the hero's two widths" do
    site = create(:site, hero_image: Rack::Test::UploadedFile.new(file_fixture("test-image.png"), "image/png"))
    hero = site.reload.hero_image

    expect(File.extname(hero.webp.path)).to eq(".webp")
    expect(MiniMagick::Image.open(hero.webp.path).dimensions).to eq([2260, 700])
    expect(MiniMagick::Image.open(hero.standard_webp.path)).to have_attributes(type: "WEBP", dimensions: [1130, 350])
  end

  # ImageMagick misreports a WebP's quality, so this compares against the same copy at the source's quality (89)
  it "makes WebP copies at a fixed quality, not the source's" do
    site = create(:site, hero_image: Rack::Test::UploadedFile.new(file_fixture("test_image.jpg"), "image/jpeg"))
    at_source_quality = ImageProcessing::MiniMagick.source(file_fixture("test_image.jpg").to_s)
                                                   .resize_to_fill(2260, 700).convert("webp").saver(quality: 89).call

    expect(File.size(site.reload.hero_image.webp.path)).to be < at_source_quality.size
  end
end
