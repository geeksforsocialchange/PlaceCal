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

  # @label Cancelled, page view
  # @notes A notice above the details says the event is cancelled.
  def cancelled_page
    render Components::Sites::Event.new(display_context: :page, event: PreviewSupport.sample_event(status: "cancelled"))
  end

  # @label Postponed, list view
  def postponed_card
    render Components::Sites::Event.new(event: PreviewSupport.sample_event(status: "postponed"))
  end

  # @label Postponed, page view
  def postponed_page
    render Components::Sites::Event.new(display_context: :page, event: PreviewSupport.sample_event(status: "postponed"))
  end

  # @label Online event
  def online_event
    render Components::Sites::Event.new(display_context: :list, event: PreviewSupport.sample_online_event)
  end

  # @label Online services
  # @notes Known meeting and streaming hosts are named; anything else says "Online".
  def online_services
    render CardList.new(OnlinePreviewSupport.events)
  end

  # @label Card with every detail
  def full_card
    render Components::Sites::Event.new(display_context: :list, event: PreviewSupport.sample_full_event, show_neighbourhoods: true)
  end

  # @label Page with every detail
  def full_page
    render Components::Sites::Event.new(display_context: :page, event: PreviewSupport.sample_full_event)
  end

  # @label Long-running, list view
  # @notes An event of more than 3 days says when it runs until in place of its times.
  def long_running_card
    render Components::Sites::Event.new(display_context: :list, event: LongRunningPreviewSupport.event)
  end

  # @label Long-running, page view
  # @notes The date line gives the whole range, with no time line.
  def long_running_page
    render Components::Sites::Event.new(display_context: :page, event: LongRunningPreviewSupport.event)
  end

  # @label Tickets, list view
  # @notes After the times on the time line: Free, the lowest price, or sold out, which wins over the price.
  def tickets_card
    render CardList.new(TicketPreviewSupport.events)
  end

  # @label Tickets, page view
  # @notes The price, and that it's sold out when it is.
  def tickets_page
    render Components::Sites::Event.new(display_context: :page, event: TicketPreviewSupport.events[2])
  end

  # @label Repeating event
  def repeating_event
    render Components::Sites::Event.new(display_context: :list, event: PreviewSupport.sample_repeating_event)
  end

  class CardList < Phlex::HTML
    def initialize(events)
      super()
      @events = events
    end

    def view_template
      div { @events.each { render Components::Sites::Event.new(display_context: :list, event: it) } }
    end
  end
end
