# frozen_string_literal: true

# A sans section heading with a rule under it, as on the partner and event pages. Size comes from the call site.
class Components::UI::RuledHeading < Components::Base
  RULES = { inline: 'inline-block', full: 'block' }.freeze

  prop :level, _Union(1, 2, 3, 4), default: 2
  prop :caps, _Boolean, default: false
  prop :rule, _Union(*RULES.keys), default: :inline
  prop :attributes, Hash, :**

  def view_template(&)
    css = ['ruled-heading text-foreground pb-2 border-b-3 border-rules', RULES[@rule],
           @caps ? 'allcaps' : 'font-bold', @attributes[:class]].compact.join(' ')
    public_send(:"h#{@level}", class: css, **@attributes.except(:class), &)
  end
end
