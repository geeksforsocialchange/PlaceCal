# frozen_string_literal: true

class UI::RuledHeadingPreview < Lookbook::Preview
  # Allcaps with a full-width rule: the partner page's Get in touch, Address and Opening times.
  # @label Caps, full rule
  def caps_full
    render(Components::UI::RuledHeading.new(caps: true, rule: :full)) { "Opening times" }
  end

  # Bold with the rule under the text only: the event page's information columns.
  # @label Plain, inline rule
  def plain_inline
    render(Components::UI::RuledHeading.new) { "Event address" }
  end

  # Small, centred caps titling a card, with `spacing: :card` below it; `:illustrated` adds room above for a picture, as on the help cards.
  # @label Card title
  def card_title
    render(Components::UI::RuledHeading.new(level: 3, caps: true, tone: :secondary, rule: :centered, size: :sm, spacing: :card)) { "Your local contact" }
  end

  # Allcaps with no rule, heading a list whose rows carry their own: an event page's More from.
  # @label Caps, no rule
  def caps_no_rule
    render(Components::UI::RuledHeading.new(caps: true, rule: :none, size: :lg)) { "More from Hulme Garden Centre" }
  end
end
