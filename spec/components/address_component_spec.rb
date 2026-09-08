# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Address, type: :component do
  let(:address) { create(:riverside_address) }
  let(:raw_location) { "Unformatted Address, Ungeolocated Lane" }

  it "renders address information" do
    render_inline(described_class.new(address: address, raw_location: raw_location))

    expect(page).to have_text(address.street_address)
    expect(page).to have_text(address.postcode)
  end

  it "renders with just an address" do
    render_inline(described_class.new(address: address, raw_location: nil))

    expect(page).to have_text(address.street_address)
  end

  it "renders with raw location when no address" do
    render_inline(described_class.new(address: nil, raw_location: raw_location))

    expect(page).to have_text(raw_location)
  end

  describe "directions link" do
    it "links to Google Maps using the coordinates when present" do
      render_inline(described_class.new(address: address, raw_location: nil))

      link = page.find("a.place_info__directions")
      expect(link[:href]).to eq(
        "https://www.google.com/maps/dir/?api=1&destination=#{address.latitude},#{address.longitude}"
      )
      expect(link.text).to eq("Directions")
      expect(link[:target]).to eq("_blank")
      expect(link[:rel]).to eq("noopener")
    end

    it "falls back to the postcode-bearing address when there are no coordinates" do
      address.latitude = nil
      address.longitude = nil

      render_inline(described_class.new(address: address, raw_location: nil))

      link = page.find("a.place_info__directions")
      expect(link[:href]).to eq(
        "https://www.google.com/maps/dir/?api=1&destination=#{CGI.escape(address.to_s)}"
      )
    end

    it "is absent without an address" do
      render_inline(described_class.new(address: nil, raw_location: raw_location))

      expect(page).not_to have_css("a.place_info__directions")
    end
  end
end
