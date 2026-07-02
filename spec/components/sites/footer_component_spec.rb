# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Sites::Footer, type: :component do
  context "when APP_VERSION is set" do
    before do
      stub_const("ENV", ENV.to_hash.merge("APP_VERSION" => "v0.9.1"))
    end

    it "shows the version label linking to the release tag" do
      render_inline(described_class.new(nil))

      link = page.find("a", text: "v0.9.1")
      expect(link[:href])
        .to eq("https://github.com/geeksforsocialchange/PlaceCal/releases/tag/v0.9.1")
    end
  end

  context "when neither APP_VERSION nor GIT_REV is set" do
    before do
      env = ENV.to_hash
      env.delete("APP_VERSION")
      env.delete("GIT_REV")
      stub_const("ENV", env)
    end

    it "falls back to a 'main' build label linking to the repo" do
      render_inline(described_class.new(nil))

      link = page.find("a", text: "main")
      expect(link[:href]).to eq("https://github.com/geeksforsocialchange/PlaceCal")
    end
  end
end
