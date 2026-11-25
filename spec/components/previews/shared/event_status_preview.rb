# frozen_string_literal: true

class Shared::EventStatusPreview < Lookbook::Preview
  include PreviewSupport

  # @label Cancelled
  def cancelled
    render Components::Shared::EventStatus.new(event: PreviewSupport.sample_event(status: "cancelled"))
  end

  # @label Postponed
  def postponed
    render Components::Shared::EventStatus.new(event: PreviewSupport.sample_event(status: "postponed"))
  end

  # @label Inline
  # @notes A bold word at the line's own size, leading an event card's time line.
  def inline
    render Components::Shared::EventStatus.new(event: PreviewSupport.sample_event(status: "cancelled"), look: :inline)
  end
end
