# frozen_string_literal: true

# The small allcaps label above a heading, over a stat or at the top of a sidebar card.
class Components::UI::Kicker < Components::Base
  # :strong is the darker ink for kickers on a secondary band; :faded dims the surrounding colour on a dark band.
  TONES = { muted: 'text-tertiary', accent: 'text-secondary-strong', foreground: 'text-foreground', strong: 'text-foreground-dark',
            faded: 'opacity-80', inherit: nil }.freeze
  TAGS = %i[div span p h2 h3 h4 footer].freeze

  prop :tone, _Union(*TONES.keys), default: :inherit
  prop :as, _Union(*TAGS), default: :div
  prop :spacing, _Union(*UI::Heading::SPACING.keys), default: :inherit
  prop :attributes, Hash, :**

  def view_template(&)
    css = ['allcaps-label', TONES[@tone], UI::Heading::SPACING[@spacing], @attributes[:class]].compact.join(' ')
    public_send(@as, class: css, **@attributes.except(:class), &)
  end
end
