# frozen_string_literal: true

class Components::UI::Heading < Components::Base
  # :item heads one card in a list of features; :card a card or panel; :title and :display a marketing page's sections.
  SIZES = { section: 'text-section', subhead: 'text-subhead', item: 'text-lg', card: 'text-card', title: 'text-3xl leading-tight',
            display: 'text-display leading-tight' }.freeze
  # :strong is the darker ink for headings on a coloured band; :inherit takes the colour of a card around it.
  TONES = { foreground: 'text-foreground', strong: 'text-foreground-dark', inherit: nil }.freeze
  # :inherit keeps the base heading margins; the steps drop the top margin and space what follows on the layout scale.
  SPACING = { inherit: nil, none: 'my-0', xs: 'mt-0 mb-1', sm: 'mt-0 mb-2', md: 'mt-0 mb-4', lg: 'mt-0 mb-6', xl: 'mt-0 mb-8' }.freeze

  prop :level, _Union(1, 2, 3, 4), default: 2
  prop :size, _Union(*SIZES.keys), default: :section
  prop :tone, _Union(*TONES.keys), default: :foreground
  prop :spacing, _Union(*SPACING.keys), default: :inherit
  # Evens out the line lengths of a heading that wraps.
  prop :balance, _Boolean, default: false
  prop :attributes, Hash, :**

  def view_template(&)
    css = ['font-serif font-regular', TONES[@tone], SIZES[@size], SPACING[@spacing], ('text-balance' if @balance), @attributes[:class]]
    public_send(:"h#{@level}", class: css.compact.join(' '), **@attributes.except(:class), &)
  end
end
