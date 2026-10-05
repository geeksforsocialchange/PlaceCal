# frozen_string_literal: true

require "rails_helper"
require "neighbourhood_remapper"

RSpec.describe NeighbourhoodRemapper do
  # Suppress progress output from the remapper
  before { allow($stdout).to receive(:puts) }

  let(:old_release) { DateTime.new(2019, 12) }

  let(:district) { create(:neighbourhood, unit: "district", name: "Tameside") }
  let(:old_ward) do
    create(:neighbourhood, name: "Mossley", unit: "ward", release_date: old_release, parent: district)
  end
  let(:new_ward) { create(:neighbourhood, name: "Mossley", unit: "ward", parent: district) }

  describe "matching by unit + name + parent" do
    let!(:sites_neighbourhood) { create(:sites_neighbourhood, neighbourhood: old_ward) }
    let!(:service_area) { create(:service_area, neighbourhood: old_ward) }
    let!(:neighbourhoods_user) { NeighbourhoodsUser.create!(user: create(:user), neighbourhood: old_ward) }

    before { new_ward }

    it "remaps all three association tables to the latest-release row" do
      summary = described_class.run

      expect(summary[:remapped]).to eq(3)
      expect(sites_neighbourhood.reload.neighbourhood).to eq(new_ward)
      expect(service_area.reload.neighbourhood).to eq(new_ward)
      expect(neighbourhoods_user.reload.neighbourhood).to eq(new_ward)
    end

    it "is idempotent" do
      described_class.run
      summary = described_class.run

      expect(summary).to eq(remapped: 0, deleted: 0, skipped: [])
      expect(sites_neighbourhood.reload.neighbourhood).to eq(new_ward)
    end

    it "makes no changes in dry-run mode but reports what it would do" do
      summary = described_class.run(dry_run: true)

      expect(summary[:remapped]).to eq(3)
      expect(sites_neighbourhood.reload.neighbourhood).to eq(old_ward)
      expect(service_area.reload.neighbourhood).to eq(old_ward)
      expect(neighbourhoods_user.reload.neighbourhood).to eq(old_ward)
    end
  end

  describe "matching by unit code" do
    it "prefers a latest-release row with the same code even when renamed" do
      old = create(:neighbourhood, name: "Old Name", unit: "ward", release_date: old_release,
                                   unit_code_value: "E05099999", parent: district)
      renamed = create(:neighbourhood, name: "New Name", unit: "ward",
                                       unit_code_value: "E05099999", parent: district)
      link = create(:sites_neighbourhood, neighbourhood: old)

      described_class.run

      expect(link.reload.neighbourhood).to eq(renamed)
    end
  end

  describe "duplicate handling" do
    it "deletes the stale row when the owner is already linked to the replacement" do
      new_ward
      site = create(:site)
      stale_link = create(:sites_neighbourhood, site: site, neighbourhood: old_ward)
      create(:sites_neighbourhood, site: site, neighbourhood: new_ward, relation_type: "Secondary")

      summary = described_class.run

      expect(summary[:deleted]).to eq(1)
      expect(SitesNeighbourhood.exists?(stale_link.id)).to be false
      expect(site.sites_neighbourhoods.count).to eq(1)
    end

    it "promotes the surviving link to Primary when the deleted duplicate was Primary" do
      new_ward
      site = create(:site)
      create(:sites_neighbourhood, site: site, neighbourhood: old_ward, relation_type: "Primary")
      survivor = create(:sites_neighbourhood, site: site, neighbourhood: new_ward, relation_type: "Secondary")

      described_class.run

      expect(survivor.reload.relation_type).to eq("Primary")
    end
  end

  describe "manual review cases" do
    it "skips and reports when no latest-release replacement exists" do
      vanished = create(:neighbourhood, name: "Abolished Ward", unit: "ward", release_date: old_release,
                                        parent: district)
      link = create(:sites_neighbourhood, neighbourhood: vanished)

      summary = described_class.run

      expect(summary[:skipped]).to eq(["SitesNeighbourhood##{link.id}"])
      expect(link.reload.neighbourhood).to eq(vanished)
    end

    it "skips and reports when several candidates match and none share the parent" do
      other_district = create(:neighbourhood, unit: "district", name: "Oldham")
      orphan = create(:neighbourhood, name: "St Mary's", unit: "ward", release_date: old_release,
                                      parent: create(:neighbourhood, unit: "district", name: "Wycombe"))
      create(:neighbourhood, name: "St Mary's", unit: "ward", parent: district)
      create(:neighbourhood, name: "St Mary's", unit: "ward", parent: other_district)
      link = create(:sites_neighbourhood, neighbourhood: orphan)

      summary = described_class.run

      expect(summary[:skipped]).to eq(["SitesNeighbourhood##{link.id}"])
      expect(link.reload.neighbourhood).to eq(orphan)
    end

    it "disambiguates same-name candidates by parent name" do
      other_district = create(:neighbourhood, unit: "district", name: "Oldham")
      create(:neighbourhood, name: "Mossley", unit: "ward", parent: other_district)
      target = new_ward
      link = create(:sites_neighbourhood, neighbourhood: old_ward)

      described_class.run

      expect(link.reload.neighbourhood).to eq(target)
    end
  end

  describe "rows already on the latest release" do
    it "leaves them untouched" do
      link = create(:sites_neighbourhood, neighbourhood: new_ward)

      summary = described_class.run

      expect(summary).to eq(remapped: 0, deleted: 0, skipped: [])
      expect(link.reload.neighbourhood).to eq(new_ward)
    end
  end
end
