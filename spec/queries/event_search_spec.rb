# frozen_string_literal: true

require "rails_helper"

RSpec.describe EventSearch do
  let(:riverside) { create(:riverside_ward) }
  let(:oldtown) { create(:oldtown_ward) }
  let(:in_riverside) { create(:address, neighbourhood: riverside) }
  let(:in_oldtown) { create(:address, neighbourhood: oldtown) }
  let(:oldtown_partner) { create(:partner, address: create(:address, neighbourhood: oldtown)) }

  def search(**) = described_class.new(**).call.to_a

  it "finds events held in a place, or by organisers based or working there when the event has no address" do
    held_there = create(:event, organiser: oldtown_partner, address: in_riverside)
    based_there = create(:event, organiser: create(:partner, address: create(:address, neighbourhood: riverside)), address: nil,
                                 online_address: create(:online_address))
    serving_it = create(:partner, address: create(:address, neighbourhood: oldtown))
    serving_it.service_areas.create!(neighbourhood: riverside)
    served = create(:event, organiser: serving_it, address: nil, online_address: create(:online_address))
    create(:event, organiser: serving_it, address: in_oldtown)

    expect(search(place: "riverside")).to contain_exactly(held_there, based_there, served)
  end

  it "resolves a postcode to its ward" do
    event = create(:event, organiser: oldtown_partner, address: in_riverside)
    create(:event, organiser: oldtown_partner, address: in_oldtown)
    allow(Geocoder).to receive(:search).with("M155FS")
                                       .and_return([double(data: { "codes" => { "admin_ward" => riverside.unit_code_value } })])

    expect(search(postcode: "m15 5fs")).to eq([event])
    expect { search(postcode: "not a postcode") }.to raise_error(EventSearch::Error, /isn't a UK postcode/)
  end

  it "narrows by keyword and category" do
    tag = create(:health_wellbeing_tag)
    yoga = create(:event, summary: "Chair yoga", organiser: create(:partner, address: in_oldtown, tags: [tag]))
    create(:event, summary: "Chair yoga", organiser: oldtown_partner)
    create(:event, summary: "Knitting", organiser: create(:partner, address: in_oldtown, tags: [tag]))

    expect(search(query: "YOGA", category: tag.name.upcase)).to eq([yoga])
    expect { search(place: "Atlantis") }.to raise_error(EventSearch::Error, /No PlaceCal area called Atlantis/)
  end
end
