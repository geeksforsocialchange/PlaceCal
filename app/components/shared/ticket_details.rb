# frozen_string_literal: true

# How an event's price and sold-out state read, shared by event cards, rows and pages.
module Components::Shared::TicketDetails
  private

  # One short label for a row, sold out before the price
  def ticket_label
    return if ticket_details_hidden?

    sold_out? ? t('events.tickets.sold_out') : price_text
  end

  # The price and, when it applies, that it's sold out
  def ticket_summary
    return if ticket_details_hidden?

    price = price_text
    return price unless sold_out?

    price ? t('events.tickets.price_sold_out', price:) : t('events.tickets.sold_out')
  end

  # A called-off event's status says more than its price
  def ticket_details_hidden? = Components::Shared::EventStatus.called_off?(@event)

  # nil means the source doesn't say
  def sold_out? = @event.try(:sold_out) == true

  def price_text
    price = @event.try(:price_from)
    return if price.nil?
    return t('events.tickets.free') if price.zero?

    currency = @event.try(:price_currency)
    t('events.tickets.from', price: formatted_price(price, currency)) if currency.present?
  end

  # £5 or £5.50; currencies without a symbol in the locale read as their code, "USD 5"
  def formatted_price(price, currency)
    unit = t("events.tickets.currency_units.#{currency}", default: '')
    precision = (price % 1).zero? ? 0 : 2
    format = unit.present? ? '%u%n' : '%u %n'
    ActiveSupport::NumberHelper.number_to_currency(price, unit: unit.presence || currency, precision:, format:)
  end
end
