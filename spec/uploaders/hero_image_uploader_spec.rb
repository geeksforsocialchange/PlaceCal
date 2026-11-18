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
end
