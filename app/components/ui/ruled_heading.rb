# frozen_string_literal: true

# A sans section heading with a rule under it, as on the partner and event pages. Spacing around it comes from its parent.
class Components::UI::RuledHeading < Components::Base
  # :centered keeps the rule under the words but stays a block, so it sits on its own line and its margins collapse.
  RULES = { inline: 'inline-block', full: 'block', centered: 'block w-fit mx-auto' }.freeze
  # The rule's colour; :background and :secondary for headings on a rules-coloured band or a card.
  TONES = { rules: 'border-rules', background: 'border-background', secondary: 'border-secondary' }.freeze
  # :inherit keeps the base heading size for its level.
  SIZES = { inherit: nil, sm: 'text-base', lg: 'text-xl' }.freeze

  prop :level, _Union(1, 2, 3, 4), default: 2
  prop :caps, _Boolean, default: false
  prop :rule, _Union(*RULES.keys), default: :inline
  prop :tone, _Union(*TONES.keys), default: :rules
  prop :size, _Union(*SIZES.keys), default: :inherit
  prop :attributes, Hash, :**

  def view_template(&)
    css = ['ruled-heading text-foreground pb-2 border-b-3', TONES[@tone], RULES[@rule], SIZES[@size],
           @caps ? 'allcaps' : 'font-bold', @attributes[:class]].compact.join(' ')
    public_send(:"h#{@level}", class: css, **@attributes.except(:class), &)
  end
end
