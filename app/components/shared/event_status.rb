# frozen_string_literal: true

# The word saying an event is cancelled or postponed, at the start of its struck-through details
class Components::Shared::EventStatus < Components::Base
  CALLED_OFF = %w[cancelled postponed].freeze

  theme_scope :event_status,
              parts: { root: 'The word "Cancelled" or "Postponed"; the variant says which. Only for an event that is called off.' },
              variants: { root: CALLED_OFF.map(&:to_sym) },
              tokens: %i[--text-2xs --font-weight-bold --tracking-badge]

  # A badge before struck-through details, or a bold word leading a sentence-like line such as the card's time line
  LOOKS = { badge: 'text-2xs font-bold uppercase tracking-badge', inline: 'font-bold' }.freeze

  prop :event, _Any
  prop :look, _Union(*LOOKS.keys), default: :badge

  # For components that also strike through the title: a test double without a status counts as scheduled
  def self.called_off?(event) = event.try(:status).to_s.in?(CALLED_OFF)

  def view_template
    return unless self.class.called_off?(@event)

    span(**part(:root, variant: @event.status.to_sym, class: LOOKS[@look])) do
      t("events.status.#{@event.status}")
    end
  end
end
