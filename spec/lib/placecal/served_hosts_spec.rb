# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlaceCal::ServedHosts do
  describe ".from_deploy_file" do
    it "reads production's proxy hosts from the real Kamal destination file" do
      hosts = described_class.from_deploy_file("production")
      expect(hosts).to include("placecal.org", "*.placecal.org", "www.queerleeds.lgbt", "transdimension.uk")
      expect(hosts).not_to include("fruitsaladevents.co.uk")
    end

    it "reads staging's proxy hosts" do
      expect(described_class.from_deploy_file("staging")).to eq(["placecal-staging.org", "*.placecal-staging.org"])
    end

    it "is empty for an environment with no destination file" do
      expect(described_class.from_deploy_file("development")).to eq([])
    end

    it "accepts Kamal's single proxy.host" do
      Dir.mktmpdir do |dir|
        FileUtils.mkdir_p(File.join(dir, "config"))
        File.write(File.join(dir, "config/deploy.demo.yml"), "proxy:\n  host: <%= 'demo.example.org' %>\n")
        expect(described_class.from_deploy_file("demo", root: Pathname(dir))).to eq(["demo.example.org"])
      end
    end
  end

  describe ".current" do
    after { described_class.reset! }

    it "uses config.x.served_hosts when it is set" do
      described_class.reset!
      expect(described_class.current.patterns).to eq(Rails.configuration.x.served_hosts)
    end
  end

  describe "#include?" do
    subject(:hosts) { described_class.new(["placecal.org", "*.placecal.org", "Transdimension.uk"]) }

    it "matches exact hosts, ignoring case" do
      expect(hosts.include?("placecal.org")).to be(true)
      expect(hosts.include?("TRANSDIMENSION.UK")).to be(true)
    end

    it "matches one label under a wildcard" do
      expect(hosts.include?("hulme.placecal.org")).to be(true)
      expect(hosts.include?("www.hulme.placecal.org")).to be(false)
    end

    it "does not match hosts it does not list" do
      expect(hosts.include?("www.transdimension.uk")).to be(false)
      expect(hosts.include?("fruitsaladevents.co.uk")).to be(false)
      expect(hosts.include?("evilplacecal.org")).to be(false)
      expect(hosts.include?("")).to be(false)
    end
  end

  describe "#verify!" do
    it "raises when there are no hosts" do
      expect { described_class.new([]).verify! }.to raise_error(described_class::Missing)
    end

    it "passes when there are hosts" do
      expect(described_class.new(["placecal.org"]).verify!).to be_a(described_class)
    end
  end
end
