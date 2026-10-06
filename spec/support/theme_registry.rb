# frozen_string_literal: true

# Isolate specs that mutate the theme registry (PlaceCal::Extensions):
# tag an example or group with `theme_registry: true` and it starts from
# the boot-time registry and is restored afterwards.
RSpec.configure do |config|
  config.around(:each, :theme_registry) do |example|
    state = PlaceCal::Extensions.snapshot
    begin
      example.run
    ensure
      PlaceCal::Extensions.restore(state)
    end
  end
end
