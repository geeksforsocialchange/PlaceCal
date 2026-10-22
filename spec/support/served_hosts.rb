# frozen_string_literal: true

module ServedHostsHelper
  # Stands in for the deploy's proxy host list, e.g. serve_hosts("placecal.org", "*.placecal.org", "transdimension.uk").
  def serve_hosts(*hosts)
    allow(PlaceCal::ServedHosts).to receive(:current).and_return(PlaceCal::ServedHosts.new(hosts.flatten))
  end
end

RSpec.configure do |config|
  config.include ServedHostsHelper
end
