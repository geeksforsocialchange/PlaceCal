# frozen_string_literal: true

require "rails_helper"

RSpec.describe SiteEventsScope do
  let(:district) { create(:neighbourhood, name: "Scope District", unit: "district") }
  let(:ward) { create(:neighbourhood, name: "Scope Ward", unit: "ward", parent: district) }
  let(:elsewhere) { create(:neighbourhood, name: "Elsewhere Ward", unit: "ward") }
  let(:outside_partner) { create(:partner, address: create(:address, neighbourhood: elsewhere)) }

  let!(:event_in_ward) { create(:event, organiser: outside_partner, address: create(:address, neighbourhood: ward)) }
  let!(:event_elsewhere) { create(:event, organiser: outside_partner, address: create(:address, neighbourhood: elsewhere)) }

  context "with an untagged site anchored at a district" do
    let(:site) { create(:site).tap { |s| s.neighbourhoods << district } }

    it "takes events at an address anywhere in the site's subtree" do
      events = described_class.new(site:).call

      expect(events).to include(event_in_ward)
      expect(events).not_to include(event_elsewhere)
    end

    it "matches the subtree with a subquery, not an id list" do
      sql = described_class.new(site:).call.to_sql

      expect(sql).to include('"addresses"."neighbourhood_id" IN (SELECT "neighbourhoods"."id" FROM "neighbourhoods"')
      expect(sql).not_to match(/"addresses"\."neighbourhood_id" IN \(\d/)
    end
  end

  context "with an untagged site that has no neighbourhoods" do
    let(:site) { create(:site) }

    it "takes no events by address" do
      expect(described_class.new(site:).call).to be_empty
    end
  end
end
