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

  # ImageMagick misreports a WebP's quality, so this compares against the same image encoded at a high quality
  it "makes WebP copies at a fixed quality, not the source's" do
    hero = create(:site, hero_image: Rack::Test::UploadedFile.new(file_fixture("test_image.jpg"), "image/jpeg")).reload.hero_image
    at_high_quality = ImageProcessing::MiniMagick.source(hero.path).convert("webp").saver(quality: 95).call

    expect(File.size(hero.webp.path)).to be < at_high_quality.size * 0.8
  end
end
