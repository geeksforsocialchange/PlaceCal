# frozen_string_literal: true

require "rails_helper"

RSpec.describe "OgImage cards" do
  def expect_card_png(png)
    image = Vips::Image.new_from_buffer(png, "")
    expect(image.width).to eq(1200)
    expect(image.height).to eq(630)
  end

  describe OgImage::EventCard do
    let(:event) { create(:event) }

    it "renders a 1200x630 PNG" do
      expect_card_png(described_class.new(event).to_png)
    end

    it "renders an event without an end time or address" do
      event = create(:event, dtend: nil, address: nil)
      expect_card_png(described_class.new(event).to_png)
    end

    it "renders a very long title" do
      event = create(:event, summary: "A very long event name, " * 8)
      expect_card_png(described_class.new(event).to_png)
    end
  end

  describe OgImage::PartnerCard do
    it "renders a 1200x630 PNG" do
      partner = create(:partner)
      expect_card_png(described_class.new(partner).to_png)
    end

    it "renders the photo layout when the partner has an image" do
      partner = create(:partner, image: File.open(Rails.root.join("spec/fixtures/files/good-cat-picture.jpg")))
      expect_card_png(described_class.new(partner).to_png)
    end
  end

  describe OgImage::PartnershipCard do
    it "renders a 1200x630 PNG" do
      site = create(:site)
      expect_card_png(described_class.new(site).to_png)
    end

    it "renders the hero layout when the site has a hero image" do
      site = create(:site, hero_image: File.open(Rails.root.join("spec/fixtures/files/test_image.jpg")))
      expect_card_png(described_class.new(site).to_png)
    end
  end

  describe OgImage::SiteCard do
    it "renders a 1200x630 PNG" do
      site = create(:site, tagline: "The Community Calendar")
      expect_card_png(described_class.new(site).to_png)
    end

    it "renders the hero layout when the site has a hero image" do
      site = create(:site, tagline: "The Community Calendar",
                           hero_image: File.open(Rails.root.join("spec/fixtures/files/test_image.jpg")))
      expect_card_png(described_class.new(site).to_png)
    end
  end

  describe OgImage::GenericCard do
    it "renders a 1200x630 PNG" do
      expect_card_png(described_class.new.to_png)
    end
  end
end
