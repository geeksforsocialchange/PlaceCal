# frozen_string_literal: true

require "rails_helper"

RSpec.describe PartnerPreviewComponent, type: :component do
  let(:partner) { create(:riverside_partner) }
  let(:site) { create(:site) }

  it "renders partner name" do
    render_inline(described_class.new(partner: partner, site: site))

    expect(page).to have_selector("h3", text: partner.name)
  end

  it "renders partner summary" do
    render_inline(described_class.new(partner: partner, site: site))

    expect(page).to have_selector("p", text: partner.summary)
  end

  it "renders neighbourhood name" do
    render_inline(described_class.new(partner: partner, site: site))

    expect(page).to have_selector("span", text: "Riverside")
  end

  describe "with different partner types" do
    it "renders partner with service areas" do
      ward = create(:riverside_ward)
      mobile_partner = create(:mobile_partner, service_area_wards: [ward])

      render_inline(described_class.new(partner: mobile_partner, site: site))

      expect(page).to have_selector("h3", text: mobile_partner.name)
    end
  end
end
