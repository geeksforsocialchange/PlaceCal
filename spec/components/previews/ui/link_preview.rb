# frozen_string_literal: true

# @display context directory
class UI::LinkPreview < Lookbook::Preview
  # Always underlined, for links inside running text such as an event's venue and organiser.
  # @label Underline
  def underline
    render(Sentence.new do |s|
      s.plain "At "
      s.render(Components::UI::Link.new(href: "#")) { "Riverside Community Hub" }
      s.plain ", organised by "
      s.render(Components::UI::Link.new(href: "#")) { "Millbrook Arts" }
      s.plain "."
    end)
  end

  # Underlined on hover only, for lists of links such as footers and contact details.
  # @label Quiet
  def quiet
    render(Sentence.new do |s|
      s.render(Components::UI::Link.new(href: "#", variant: :quiet, size: :detail, font: :serif)) { "Our story" }
      s.plain " · "
      s.render(Components::UI::Link.new(href: "#", variant: :quiet, tone: :muted, size: :sm)) { "Privacy policy" }
    end)
  end

  # Bold, with room for an icon in the block, for standalone actions like subscribing to a calendar.
  # @label Action
  def action
    render(Components::UI::Link.new(href: "#", variant: :action, size: :sm)) { "Subscribe with iCal" }
  end

  # `size:` is `:inherit`, `:sm`, `:detail` or `:lg`; `font:` is `:inherit`, `:serif`, `:mono` or `:code`, a small mono URL that breaks anywhere.
  # @label Sizes and fonts
  def sizes_and_fonts
    render(Sentence.new do |s|
      s.render(Components::UI::Link.new(href: "#", variant: :quiet, size: :lg, font: :serif)) { "Riverside Community Hub" }
      s.plain " · "
      s.render(Components::UI::Link.new(href: "#", variant: :quiet, size: :sm, font: :serif)) { "support@placecal.org" }
      s.plain " · "
      s.render(Components::UI::Link.new(href: "#", variant: :quiet, font: :code)) { "placecal.org/partners/riverside-community-hub" }
    end)
  end

  class Sentence < Phlex::HTML
    def view_template(&)
      p(class: "text-base text-foreground", &)
    end
  end
end
