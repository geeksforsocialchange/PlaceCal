# frozen_string_literal: true

class EventPreview < Lookbook::Preview
  include PreviewSupport

  # @label List view
  def list_view
    render Components::Event.new(display_context: :list, event: PreviewSupport.sample_event)
  end

  # @label Page view
  def page_view
    render Components::Event.new(display_context: :page, event: PreviewSupport.sample_event)
  end

  # @label Online event
  def online_event
    render Components::Event.new(display_context: :list, event: PreviewSupport.sample_online_event)
  end

  # @label Repeating event
  def repeating_event
    render Components::Event.new(display_context: :list, event: PreviewSupport.sample_repeating_event)
  end
end
