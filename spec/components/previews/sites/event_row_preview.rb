# frozen_string_literal: true

# @display width page
class Sites::EventRowPreview < Lookbook::Preview
  include PreviewSupport

  # @label One event
  def single
    render Components::Sites::EventRow.new(event: PreviewSupport.sample_event)
  end

  # @label Every detail
  # @notes Time, venue, organiser, repeats, online and the neighbourhood badge.
  def every_detail
    event = PreviewSupport.sample_full_event.tap { it.partner_at_location = PartnerMock.new(id: 2, name: "Hulme Community Hall") }
    render Components::Sites::EventRow.new(event:, show_neighbourhoods: true)
  end

  # @label Cancelled and postponed
  # @notes The status word before a struck-through title, with the date and details faded.
  def called_off
    render_inline_rows(PreviewSupport.sample_event(summary: "Folk Club Sing-Around", status: "cancelled"),
                       PreviewSupport.sample_event(id: 2, summary: "Summer Fair", status: "postponed"))
  end

  private

  def render_inline_rows(*events)
    render Components::Sites::EventRows.new(events:)
  end
end
