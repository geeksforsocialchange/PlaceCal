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
      s.render(Components::UI::Link.new(href: "#", variant: :quiet, class: "font-serif text-detail")) { "Our story" }
      s.plain " · "
      s.render(Components::UI::Link.new(href: "#", variant: :quiet, tone: :muted, class: "text-sm")) { "Privacy policy" }
    end)
  end

  # Bold, with room for an icon in the block, for standalone actions like subscribing to a calendar.
  # @label Action
  def action
    render(Components::UI::Link.new(href: "#", variant: :action, class: "text-sm")) { "Subscribe with iCal" }
  end

  class Sentence < Phlex::HTML
    def view_template(&)
      p(class: "text-base text-foreground", &)
    end
  end
end
