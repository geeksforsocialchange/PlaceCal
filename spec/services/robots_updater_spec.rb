# frozen_string_literal: true

require "rails_helper"

RSpec.describe RobotsUpdater do
  let(:robots_json) do
    {
      "AlphaBot" => { "operator" => "AlphaCorp", "function" => "AI training" },
      "Applebot" => { "operator" => "Apple", "function" => "Search" },
      "BetaBot" => { "operator" => "BetaCorp", "function" => "Data scraping" },
      "ChatGPT-User" => { "operator" => "OpenAI", "function" => "Search" },
      "ClaudeBot" => { "operator" => "Anthropic", "function" => "AI training" },
      "PerplexityBot" => { "operator" => "Perplexity", "function" => "Search" }
    }.to_json
  end

  let(:default_file) { Rails.root.join("config/robots/robots.production.txt") }
  let(:strict_file) { Rails.root.join("config/robots/robots.production.strict.txt") }

  around do |example|
    original_default = default_file.read
    original_strict = strict_file.read
    example.run
  ensure
    default_file.write(original_default)
    strict_file.write(original_strict)
  end

  before do
    stub_request(:get, RobotsUpdater::ROBOTS_JSON_URL)
      .to_return(status: 200, body: robots_json, headers: { "Content-Type" => "application/json" })
  end

  describe ".call" do
    before { described_class.call(output: StringIO.new) }

    it "writes the default template allowing search bots" do
      content = default_file.read

      # Search bots should NOT be in the block list
      expect(content).not_to include("User-agent: Applebot\n")
      expect(content).not_to include("User-agent: ChatGPT-User\n")
      expect(content).not_to include("User-agent: PerplexityBot\n")

      # Training bots should be blocked
      expect(content).to include("User-agent: AlphaBot")
      expect(content).to include("User-agent: BetaBot")
      expect(content).to include("User-agent: ClaudeBot")
      expect(content).to include("Disallow: /")
    end

    it "writes the strict template blocking all bots" do
      content = strict_file.read

      # All bots should be blocked
      expect(content).to include("User-agent: Applebot")
      expect(content).to include("User-agent: ChatGPT-User")
      expect(content).to include("User-agent: PerplexityBot")
      expect(content).to include("User-agent: AlphaBot")
      expect(content).to include("User-agent: ClaudeBot")
      expect(content).to include("Disallow: /")
    end

    it "includes standard robots.txt header" do
      [default_file, strict_file].each do |file|
        content = file.read
        expect(content).to include("User-agent: *")
        expect(content).to include("Disallow: /assets/")
        expect(content).to include("ai-robots-txt")
      end
    end
  end

  context "when upstream request fails" do
    before do
      stub_request(:get, RobotsUpdater::ROBOTS_JSON_URL)
        .to_return(status: 500)
    end

    it "raises an error" do
      expect { described_class.call(output: StringIO.new) }.to raise_error(RuntimeError, /Failed to fetch robots.json/)
    end
  end
end
