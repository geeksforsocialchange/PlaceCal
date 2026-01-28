# frozen_string_literal: true

require "rails_helper"

RSpec.describe PartnersQuery, "tag filtering" do
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

  it "empty site/tag returns nothing" do
    output = described_class.new(site: site).call(tag_id: nil)
    expect(output).to be_empty
  end

  it "finds partners with tag" do
    tag = create(:tag)
    other_tag = create(:tag)

    site.neighbourhoods << geocodable_neighbourhood
    site.tags << tag
    site.tags << other_tag

    4.times do |n|
      partner = create(:partner, name: "Partner #{n}", address: address_one)
      partner.tags << tag
    end

    6.times do |n|
      partner = create(:partner, name: "Partner without tag #{n}", address: address_one)
      partner.tags << other_tag
    end

    2.times do |n|
      create(:partner, name: "Partner with no tags #{n}", address: address_one)
    end

    output = described_class.new(site: site).call(tag_id: tag.id)
    expect(output.length).to eq(4)
  end
end
