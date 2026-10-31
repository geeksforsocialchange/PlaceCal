# frozen_string_literal: true

class Sites::PageActionsPreview < Lookbook::Preview
  # @label Below the content
  def default
    render Components::Sites::PageActions.new(links: [["Visit the organiser", "#"], ["Add to calendar", "#"], ["All events", "#"]])
  end

  # @label In the meta band
  def in_meta_band
    render Components::Sites::PageActions.new(links: [["iCal", "#"], ["CSV", "#"]], in_meta_band: true)
  end
end
