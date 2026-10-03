# frozen_string_literal: true

require "rails_helper"

RSpec.describe OutboundUrlGuard do
  describe ".vet!" do
    [
      "http://127.0.0.1/",
      "http://10.1.2.3/",
      "http://169.254.169.254/latest/meta-data/",
      "http://[::1]/",
      "http://[fd12:3456::1]/",
      "http://[::ffff:127.0.0.1]/"
    ].each do |url|
      it "blocks #{url}" do
        expect { described_class.vet!(url) }.to raise_error(described_class::BlockedUrl)
        expect(described_class).not_to have_received(:resolve)
      end
    end

    it "blocks a hostname that resolves to a private address" do
      allow(described_class).to receive(:resolve).with("internal.example.com").and_return([IPAddr.new("10.0.0.5")])

      expect { described_class.vet!("https://internal.example.com/feed.ics") }.to raise_error(described_class::BlockedUrl)
    end

    it "blocks a hostname if any of its addresses is private" do
      allow(described_class).to receive(:resolve).and_return([IPAddr.new("203.0.113.10"), IPAddr.new("::1")])

      expect { described_class.vet!("https://mixed.example.com/") }.to raise_error(described_class::BlockedUrl)
    end

    it "blocks non-http schemes" do
      expect { described_class.vet!("file:///etc/passwd") }.to raise_error(described_class::BlockedUrl)
      expect { described_class.vet!("gopher://example.com/") }.to raise_error(described_class::BlockedUrl)
    end

    it "returns the vetted address for a public hostname" do
      allow(described_class).to receive(:resolve).with("example.com").and_return([IPAddr.new("93.184.215.14")])

      expect(described_class.vet!("https://example.com/calendar.ics")).to eq("93.184.215.14")
    end

    it "raises SocketError when the host does not resolve" do
      allow(described_class).to receive(:resolve).and_return([])

      expect { described_class.vet!("https://nowhere.example.com/") }.to raise_error(SocketError)
    end
  end
end
