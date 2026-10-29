# frozen_string_literal: true

# A pill-shaped GET search form: icon, borderless input and submit button.
class Components::UI::SearchBar < Components::Base
  TONES = {
    light: { bar: 'bg-background shadow-hero-search', button: :primary },
    panel: { bar: 'bg-home-background-3', button: :dark }
  }.freeze
  # The input has no outline of its own, so the bar shows keyboard focus; current colour reads on both the dark hero and a cream page.
  FOCUS = 'has-[input:focus-visible]:outline-solid has-[input:focus-visible]:outline-2 has-[input:focus-visible]:outline-offset-2 ' \
          'has-[input:focus-visible]:outline-current'
  SIZES = { md: { input: 'text-detail', button: :md }, sm: { input: 'text-sm', button: :sm } }.freeze

  prop :action, String
  prop :placeholder, String
  prop :button_label, String
  prop :name, String, default: 'q'
  prop :value, _Nilable(String), default: nil
  prop :tone, _Union(*TONES.keys), default: :panel
  prop :size, _Union(*SIZES.keys), default: :md
  prop :attributes, Hash, :**

  def view_template
    form(action: @action, method: 'get',
         class: ['flex items-center rounded-full p-1 pl-2', FOCUS, TONES[@tone][:bar], @attributes[:class]].compact.join(' '),
         **@attributes.except(:class)) do
      div(class: 'px-2 text-tertiary') { raw(view_context.icon(:search, size: nil, css_class: 'size-4')) }
      input(type: 'text', name: @name, value: @value, placeholder: @placeholder, aria_label: @placeholder,
            class: "flex-1 border-0 bg-transparent py-2 text-foreground outline-none placeholder:text-tertiary #{SIZES[@size][:input]}")
      UI::Button(variant: TONES[@tone][:button], size: SIZES[@size][:button], type: 'submit') { @button_label }
    end
  end
end
