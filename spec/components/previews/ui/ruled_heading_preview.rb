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
end
