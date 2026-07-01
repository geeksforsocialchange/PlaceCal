# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmailList do
  describe ".all" do
    it "contains the initial lists" do
      expect(described_class.all.map(&:key)).to contain_exactly(:partner_digest, :partnership_updates)
    end

    it "has i18n copy for every list" do
      described_class.all.each do |list|
        expect(list.name).not_to include("translation missing")
        expect(list.description).not_to include("translation missing")
      end
    end
  end

  describe "default policies" do
    it "treats partner_digest as opt-out (service email)" do
      expect(described_class.find(:partner_digest).default_subscribed?).to be true
    end

    it "treats partnership_updates as opt-in (explicit consent)" do
      expect(described_class.find(:partnership_updates).default_subscribed?).to be false
    end
  end

  describe ".find" do
    it "accepts strings and symbols" do
      expect(described_class.find("partner_digest")).to eq(described_class.find(:partner_digest))
    end

    it "returns nil for unknown keys" do
      expect(described_class.find(:nonsense)).to be_nil
    end
  end

  describe ".find!" do
    it "raises on unknown keys" do
      expect { described_class.find!(:nonsense) }.to raise_error(KeyError)
    end
  end
end
