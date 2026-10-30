# frozen_string_literal: true

class Components::UI::Heading < Components::Base
  SIZES = { section: 'text-section', subhead: 'text-subhead' }.freeze
  # :inherit keeps the base heading margins; the steps drop the top margin and space what follows on the layout scale.
  SPACING = { inherit: nil, none: 'my-0', xs: 'mt-0 mb-1', sm: 'mt-0 mb-2', md: 'mt-0 mb-4', lg: 'mt-0 mb-6', xl: 'mt-0 mb-8' }.freeze

  prop :level, _Union(1, 2, 3, 4), default: 2
  prop :size, _Union(*SIZES.keys), default: :section
  prop :spacing, _Union(*SPACING.keys), default: :inherit
  prop :attributes, Hash, :**

  def view_template(&)
    css = ['font-serif font-regular text-foreground', SIZES[@size], SPACING[@spacing], @attributes[:class]].compact.join(' ')
    public_send(:"h#{@level}", class: css, **@attributes.except(:class), &)
  end
end
