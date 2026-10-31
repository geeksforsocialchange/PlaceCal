# frozen_string_literal: true

# A paragraph of running text. Its colour comes from the surrounding text unless tone: says otherwise.
class Components::UI::Text < Components::Base
  # :lede is the smaller paragraph under a section heading or on a card.
  VARIANTS = { body: 'text-base leading-relaxed', lede: 'text-detail leading-relaxed' }.freeze
  TONES = { foreground: 'text-foreground', strong: 'text-foreground-dark', muted: 'text-tertiary', inherit: nil }.freeze
  MEASURES = { prose: 'max-w-(--width-prose)', prose_md: 'max-w-(--width-prose-md)', prose_lg: 'max-w-(--width-prose-lg)', none: nil }.freeze
  TAGS = %i[p div figcaption].freeze

  prop :variant, _Union(*VARIANTS.keys), default: :body
  prop :tone, _Union(*TONES.keys), default: :inherit
  prop :measure, _Union(*MEASURES.keys), default: :none
  prop :spacing, _Union(*UI::Heading::SPACING.keys), default: :inherit
  prop :as, _Union(*TAGS), default: :p
  prop :attributes, Hash, :**

  def view_template(&)
    css = [VARIANTS[@variant], TONES[@tone], MEASURES[@measure], UI::Heading::SPACING[@spacing], @attributes[:class]].compact.join(' ')
    public_send(@as, class: css, **@attributes.except(:class), &)
  end
end
