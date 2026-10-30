# frozen_string_literal: true

# A group of controls under one legend, such as a set of checkboxes.
class Components::UI::Fieldset < Components::Base
  prop :legend, String
  # A hook for themes to style the legend by.
  prop :legend_class, _Nilable(String), default: nil
  prop :attributes, Hash, :**

  def view_template(&)
    fieldset(class: ['min-w-0', @attributes[:class]].compact.join(' '), **@attributes.except(:class)) do
      legend(class: [Components::UI::Field::STRONG_LABEL, 'w-full mb-3', @legend_class].compact.join(' ')) { @legend }
      yield
    end
  end
end
