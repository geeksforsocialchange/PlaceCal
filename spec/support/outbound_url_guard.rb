# frozen_string_literal: true

# Specs never hit real DNS; any hostname resolves to a public documentation address unless a spec overrides it.
RSpec.configure do |config|
  config.before do
    allow(OutboundUrlGuard).to receive(:resolve).and_return([IPAddr.new("203.0.113.10")])
  end
end
