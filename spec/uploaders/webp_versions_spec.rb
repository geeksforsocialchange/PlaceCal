# frozen_string_literal: true

require "rails_helper"

RSpec.describe WebpVersions do
  let(:partner) { create(:partner, image: Rack::Test::UploadedFile.new(file_fixture("good-cat-picture.jpg"), "image/jpeg")) }

  it "makes WebP copies fitted to each size" do
    image = partner.reload.image

    expect(MiniMagick::Image.open(image.standard_webp.path)).to have_attributes(type: "WEBP")
    expect(MiniMagick::Image.open(image.standard_webp.path).width).to be <= 420
    expect(File.extname(image.retina_webp.path)).to eq(".webp")
  end

  it "builds a srcset of the copies" do
    image = partner.reload.image

    expect(image.webp_srcset(standard: "1x", retina: "2x"))
      .to eq("#{image.standard_webp.url} 1x, #{image.retina_webp.url} 2x")
  end

  it "puts the quality in the copies' URLs, and leaves the original's alone" do
    image = partner.reload.image

    expect(image.standard_webp.url).to end_with(".webp?q=#{WebpVersions::QUALITY}")
    expect(image.url).not_to include("?q=")
  end

  it "has no srcset until every copy exists" do
    image = partner.reload.image
    FileUtils.rm(image.retina_webp.path)

    expect(image.webp_srcset(standard: "1x", retina: "2x")).to be_nil
  end
end
