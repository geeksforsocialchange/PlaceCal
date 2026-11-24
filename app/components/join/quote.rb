# frozen_string_literal: true

# A testimonial with its credit. Takes translated strings.
class Components::Join::Quote < Components::Join::Base
  # Pick the surface that differs from the section behind it: the page itself is the :light colour.
  SURFACES = { light: 'bg-home-background', shaded: 'bg-home-background-3' }.freeze

  prop :text, String
  prop :by, String
  prop :surface, _Union(*SURFACES.keys), default: :shaded

  def view_template
    blockquote(class: "#{SURFACES[@surface]} border-l-5 border-secondary-deep rounded-sm p-6 m-0") do
      p(class: 'font-serif text-card leading-snug mt-0 mb-3') { @text }
      UI::Kicker(as: :footer, tone: :muted) { @by }
    end
  end
end
