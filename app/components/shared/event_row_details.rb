# frozen_string_literal: true

# Which details an event row shows and how it words them, shared by the directory's and the sites' rows.
module Components::Shared::EventRowDetails
  private

  def show_place?
    partner = @event.partner_at_location
    address = @event.address&.street_address
    return false if partner.blank? && address.blank?
    return true if @context_partner.blank?

    partner != @context_partner
  end

  def show_organiser?
    organiser = @event.try(:organiser)
    return false if organiser.blank?
    return false if organiser == @event.partner_at_location
    return false if organiser == @context_partner

    true
  end

  def repeats
    ::Event.rrule_frequency(@event.rrule)&.titleize
  end

  def fmt_time(time)
    time.strftime('%M') == '00' ? time.strftime('%l%P').strip : time.strftime('%l:%M%P').strip
  end
end
