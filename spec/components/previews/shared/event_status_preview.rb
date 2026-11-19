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
end
