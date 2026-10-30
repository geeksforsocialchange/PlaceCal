# frozen_string_literal: true

class Sites::EventPreview < Lookbook::Preview
  include PreviewSupport

  # @label List view
  def list_view
    render Components::Sites::Event.new(display_context: :list, event: PreviewSupport.sample_event)
  end

  # @label Page view
  def page_view
    render Components::Sites::Event.new(display_context: :page, event: PreviewSupport.sample_event)
  end

  # @label Online event
  def online_event
    render Components::Sites::Event.new(display_context: :list, event: PreviewSupport.sample_online_event)
  end

  # @label Card with every detail
  def full_card
    render Components::Sites::Event.new(display_context: :list, event: PreviewSupport.sample_full_event, show_neighbourhoods: true)
  end

  # @label Page with every detail
  def full_page
    render Components::Sites::Event.new(display_context: :page, event: PreviewSupport.sample_full_event, back: ["All events", "/events"])
  end

  # @label Repeating event
  def repeating_event
    render Components::Sites::Event.new(display_context: :list, event: PreviewSupport.sample_repeating_event)
  end
end
