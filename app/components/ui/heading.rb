# frozen_string_literal: true

class Components::UI::Heading < Components::Base
  SIZES = { section: 'text-section', subhead: 'text-subhead' }.freeze

  prop :level, _Union(1, 2, 3, 4), default: 2
  prop :size, _Union(*SIZES.keys), default: :section
  prop :attributes, Hash, :**

  def view_template(&)
    css = ['font-serif font-regular text-foreground', SIZES[@size], @attributes[:class]].compact.join(' ')
    public_send(:"h#{@level}", class: css, **@attributes.except(:class), &)
  end
end
