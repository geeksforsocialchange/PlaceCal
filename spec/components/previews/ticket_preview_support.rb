# frozen_string_literal: true

# Events with ticket details for Lookbook previews: free, priced, sold out at a price, and sold out with no price.
module TicketPreviewSupport
  module_function

  def events
    [PreviewSupport.sample_event(id: 11, summary: "Seed Swap", price_from: BigDecimal(0)),
     PreviewSupport.sample_event(id: 12, summary: "Ceilidh", price_from: BigDecimal(5), price_currency: "GBP"),
     PreviewSupport.sample_event(id: 13, summary: "Comedy Night", price_from: BigDecimal("7.50"), price_currency: "GBP", sold_out: true),
     PreviewSupport.sample_event(id: 14, summary: "Book Club", sold_out: true)]
  end
end
