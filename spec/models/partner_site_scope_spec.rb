# frozen_string_literal: true

require "rails_helper"

RSpec.describe PartnersQuery, "site filtering" do
  # NOTE: these MUST match up with the geocoder response defined in spec/support/normal_island_geocoder.rb
  let(:post_code) { "M15 5DD" }
  let(:unit) { "ward" }
  let(:unit_code) { "E05011368" }
  let(:unit_name) { "Hulme" }
  let(:unit_code_key) { "WD19CD" }
  let(:release_date) { DateTime.new(2023, 7) }

  let(:site) { create(:site) }
  let(:geocodable_neighbourhood) do
    create(
      :bare_neighbourhood,
      unit: unit,
      unit_name: unit_name,
      unit_code_key: unit_code_key,
      unit_code_value: unit_code,
      release_date: release_date
    )
  end
  # Must explicitly set neighbourhood - factory skips geocoding
  let(:address_one) { create(:bare_address_1, postcode: post_code, neighbourhood: geocodable_neighbourhood) }

  before do
    Neighbourhood.destroy_all
  end

  it "empty site returns nothing" do
    output = described_class.new(site: site).call
    expect(output).to be_empty
  end

  it "can find partners in site with address" do
    site.neighbourhoods << geocodable_neighbourhood

    create_list(:partner, 5, address: address_one)

    output = described_class.new(site: site).call
    expect(output.count).to eq(5)
  end

  it "can find partners in site with service areas (without duplicates)" do
    neighbourhood_a = create(:bare_neighbourhood)
    site.neighbourhoods << neighbourhood_a

    neighbourhood_b = create(:bare_neighbourhood)
    site.neighbourhoods << neighbourhood_b

    # partners with multiple service areas in same site
    5.times do
      partner = build(:partner, address: nil)
      partner.service_area_neighbourhoods << neighbourhood_a
      partner.service_area_neighbourhoods << neighbourhood_b
      partner.save!
    end

    output = described_class.new(site: site).call
    expect(output.count).to eq(5)
  end

  it "can find partners by address and service_area" do
    neighbourhood_a = create(:bare_neighbourhood)
    site.neighbourhoods << neighbourhood_a

    neighbourhood_b = geocodable_neighbourhood
    site.neighbourhoods << neighbourhood_b

    # partner by service area
    partner = build(:partner, address: nil)
    partner.service_area_neighbourhoods << neighbourhood_b
    partner.save!

    # partner by address
    create(:partner, address: address_one)

    output = described_class.new(site: site).call
    expect(output.count).to eq(2)
  end

  it "ignores partners on other sites" do
    neighbourhood_a = create(:bare_neighbourhood)
    site.neighbourhoods << neighbourhood_a

    neighbourhood_b = create(:bare_neighbourhood)
    site.neighbourhoods << neighbourhood_b

    neighbourhood_c = create(:bare_neighbourhood)

    # our site
    3.times do
      partner = build(:partner, address: nil)
      partner.service_area_neighbourhoods << neighbourhood_a
      partner.service_area_neighbourhoods << neighbourhood_b
      partner.save!
    end

    # other site
    other_site = create(:site)
    other_site.neighbourhoods << neighbourhood_b
    other_site.neighbourhoods << neighbourhood_c

    7.times do
      partner = build(:partner, address: nil)
      partner.service_area_neighbourhoods << neighbourhood_b
      partner.service_area_neighbourhoods << neighbourhood_c
      partner.save!
    end

    2.times do
      partner = build(:partner, address: nil)
      partner.service_area_neighbourhoods << neighbourhood_c
      partner.save!
    end

    # finds set (neighbourhood_a OR neighbourhood_b)
    output = described_class.new(site: site).call
    expect(output.count).to eq(10)
  end

  describe "with tags" do
    def create_partner_with_tags(neighbourhood, *tags)
      partner = build(:partner, address: nil)
      partner.service_area_neighbourhoods << neighbourhood
      tags.each do |tag|
        partner.tags << tag
      end
      partner.save!
      partner
    end

    it "only finds partners with tags if site has tags" do
      tag = create(:tag)
      other_tag = create(:tag)

      site.neighbourhoods << geocodable_neighbourhood
      site.tags << tag
      site.tags << other_tag

      # present
      partner_a = create_partner_with_tags(geocodable_neighbourhood, tag)
      # present
      partner_b = create_partner_with_tags(geocodable_neighbourhood, other_tag)
      # present
      partner_c = create_partner_with_tags(geocodable_neighbourhood, tag, other_tag)
      # skipped
      create_partner_with_tags(geocodable_neighbourhood)

      found = described_class.new(site: site).call
      expect(found.count).to eq(3)

      found_ids = found.map(&:id)
      should_be_ids = [partner_a.id, partner_b.id, partner_c.id]

      expect(found_ids).to match_array(should_be_ids)
    end
  end
end
