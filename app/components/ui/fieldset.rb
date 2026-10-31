# frozen_string_literal: true

# A group of controls under one legend, such as a set of checkboxes.
class Components::UI::Fieldset < Components::Base
  prop :legend, String
  # Attributes for the legend, such as a theming part.
  prop :legend_attributes, Hash, default: -> { {} }
  prop :attributes, Hash, :**

  def view_template(&)
    fieldset(class: ['min-w-0', @attributes[:class]].compact.join(' '), **@attributes.except(:class)) do
      legend(class: [Components::UI::Field::STRONG_LABEL, 'w-full mb-3', @legend_attributes[:class]].compact.join(' '), **@legend_attributes.except(:class)) { @legend }
      yield
    end
  end
end
