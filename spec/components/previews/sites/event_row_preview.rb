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
end
