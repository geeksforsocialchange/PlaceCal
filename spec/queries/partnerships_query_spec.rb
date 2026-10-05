# frozen_string_literal: true

require "rails_helper"

RSpec.describe PartnershipsQuery do
  describe "#call" do
    it "returns only published sites" do
      published = create(:site, is_published: true)
      create(:site, is_published: false)

      expect(described_class.new.call).to contain_exactly(published)
    end

    it "orders by partner count, most partners first" do
      few = create(:site, is_published: true, partners_count: 1)
      many = create(:site, is_published: true, partners_count: 9)

      expect(described_class.new.call.to_a).to eq([many, few])
    end

    context "with a search query" do
      it "matches on name" do
        match = create(:site, is_published: true, name: "Manchester Calendar")
        create(:site, is_published: true, name: "Leeds Calendar")

        expect(described_class.new.call(query: "manchester")).to contain_exactly(match)
      end

      it "matches on description" do
        match = create(:site, is_published: true, description: "Covers the whole of Yorkshire")
        create(:site, is_published: true, description: "Somewhere else entirely")

        expect(described_class.new.call(query: "yorkshire")).to contain_exactly(match)
      end

      it "ignores a blank query" do
        site = create(:site, is_published: true)

        expect(described_class.new.call(query: "")).to contain_exactly(site)
      end
    end
  end
end
