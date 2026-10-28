# frozen_string_literal: true

# @display context directory
# @display width page
class Directory::EventRowPreview < Lookbook::Preview
  include PreviewSupport

  # @label List of events
  # @notes Two columns, as on the directory events page.
  def list
    render RowGrid.new(sample_events)
  end

  # @label Single event
  def single
    render RowGrid.new([PreviewSupport.sample_event])
  end

  # @label Repeating online event
  def repeating_online
    render RowGrid.new([PreviewSupport.sample_repeating_event.tap { it.online_address = "https://zoom.us/meeting/123" }])
  end

  private

  def sample_events
    [
      PreviewSupport.sample_event(summary: "Storytelling Evening"),
      PreviewSupport.sample_event(id: 2, summary: "Art Exhibition Opening", online_address: "https://example.org/live"),
      PreviewSupport.sample_repeating_event,
      PreviewSupport.sample_event(id: 4, summary: "Film Screening and Discussion"),
      PreviewSupport.sample_event(id: 5, summary: "Children's Storytime"),
      PreviewSupport.sample_event(id: 6, summary: "Spoken Word Open Mic")
    ]
  end

  class RowGrid < Phlex::HTML
    def initialize(events)
      super()
      @events = events
    end

    def view_template
      div(class: "grid md:grid-cols-2 gap-x-6 text-foreground") do
        @events.each { render Components::Directory::EventRow.new(event: it) }
      end
    end
  end
end
