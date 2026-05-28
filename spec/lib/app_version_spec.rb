# frozen_string_literal: true

require "rails_helper"

RSpec.describe AppVersion do
  describe ".label" do
    it "returns APP_VERSION when set" do
      stub_const("ENV", ENV.to_hash.merge("APP_VERSION" => "v0.9.1", "GIT_REV" => "abcdef1234567"))
      expect(described_class.label).to eq("v0.9.1")
    end

    it "falls back to the short GIT_REV when APP_VERSION is unset" do
      env = ENV.to_hash.merge("GIT_REV" => "abcdef1234567")
      env.delete("APP_VERSION")
      stub_const("ENV", env)
      expect(described_class.label).to eq("abcdef1")
    end

    it "falls back to the given fallback when neither is set" do
      env = ENV.to_hash
      env.delete("APP_VERSION")
      env.delete("GIT_REV")
      stub_const("ENV", env)
      expect(described_class.label(fallback: "dev")).to eq("dev")
      expect(described_class.label(fallback: "main")).to eq("main")
    end

    it "treats a blank APP_VERSION as unset" do
      stub_const("ENV", ENV.to_hash.merge("APP_VERSION" => "", "GIT_REV" => "abcdef1234567"))
      expect(described_class.label).to eq("abcdef1")
    end
  end

  describe ".url" do
    it "links to the release tag page when APP_VERSION is an exact tag" do
      stub_const("ENV", ENV.to_hash.merge("APP_VERSION" => "v0.9.1"))
      expect(described_class.url)
        .to eq("https://github.com/geeksforsocialchange/PlaceCal/releases/tag/v0.9.1")
    end

    it "strips the git-describe suffix when building the release tag link" do
      stub_const("ENV", ENV.to_hash.merge("APP_VERSION" => "v0.27.3-115-g0b8e07e8"))
      expect(described_class.url)
        .to eq("https://github.com/geeksforsocialchange/PlaceCal/releases/tag/v0.27.3")
    end

    it "links to the commit diff when only GIT_REV is set" do
      env = ENV.to_hash.merge("GIT_REV" => "abcdef1234567")
      env.delete("APP_VERSION")
      stub_const("ENV", env)
      expect(described_class.url)
        .to eq("https://github.com/geeksforsocialchange/PlaceCal/commit/abcdef1234567")
    end

    it "links to the repository home when nothing is set" do
      env = ENV.to_hash
      env.delete("APP_VERSION")
      env.delete("GIT_REV")
      stub_const("ENV", env)
      expect(described_class.url).to eq("https://github.com/geeksforsocialchange/PlaceCal")
    end
  end
end
