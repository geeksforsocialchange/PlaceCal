# frozen_string_literal: true

# A long-running event for Lookbook previews: it runs for weeks, so it shows its dates rather than its opening hours.
module LongRunningPreviewSupport
  module_function

  def event(overrides = {})
    PreviewSupport.sample_event(id: 8, summary: "Birds in our World", description: "An exhibition of birds from the museum's collection.",
                                dtstart: Time.zone.parse("2025-06-10 10:00"), dtend: Time.zone.parse("2025-08-31 17:00"), **overrides)
  end
end
