# frozen_string_literal: true

class Components::Shared::Button < Components::Base
  VARIANTS = %i[primary dark outline dark_outline light join].freeze
  SIZES = %i[sm md lg].freeze
  SHAPES = %i[pill field].freeze

  prop :variant, _Union(*VARIANTS)
  prop :size, _Union(*SIZES), default: :md
  # :field squares the corners and matches the height of the filter form controls.
  prop :shape, _Union(*SHAPES), default: :pill
  prop :href, _Nilable(String), default: nil
  prop :type, String, default: 'button'
  prop :attributes, Hash, :**

  # For buttons that have to stay Rails form helpers (form.submit, submit_tag).
  def self.classes(variant:, size: :md, shape: :pill)
    raise ArgumentError, "unknown button variant #{variant.inspect}" unless VARIANTS.include?(variant)
    raise ArgumentError, "unknown button size #{size.inspect}" unless SIZES.include?(size)
    raise ArgumentError, "unknown button shape #{shape.inspect}" unless SHAPES.include?(shape)

    ['button', "button--#{variant.to_s.dasherize}", "button--#{size}", ('button--field' if shape == :field)].compact.join(' ')
  end

  def view_template(&)
    css = [self.class.classes(variant: @variant, size: @size, shape: @shape), @attributes[:class]].compact.join(' ')
    attributes = @attributes.except(:class)

    if @href
      a(href: @href, class: "with-no-sass #{css}", **attributes, &)
    else
      button(type: @type, class: css, **attributes, &)
    end
  end
end
