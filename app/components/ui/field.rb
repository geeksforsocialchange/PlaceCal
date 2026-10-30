# frozen_string_literal: true

class Components::UI::Field < Components::Base
  VARIANTS = {
    caps: { wrapper: nil, label: 'block allcaps-label text-tertiary mb-1' },
    # Sentence-case bold label, for a form laid out as a grid of fields
    strong: { wrapper: 'flex flex-col gap-1.5 min-w-0', label: 'flex items-center gap-1.25 font-bold text-detail text-foreground' }
  }.freeze

  prop :label, String
  # The id of the control the label is for.
  prop :id, String
  prop :hint, _Nilable(String), default: nil
  prop :variant, _Union(*VARIANTS.keys), default: :caps
  # true marks the label with an asterisk, false with "optional"; nil marks nothing.
  prop :required, _Nilable(_Boolean), default: nil
  # A hook for themes to style the label by.
  prop :label_class, _Nilable(String), default: nil
  prop :attributes, Hash, :**

  def view_template
    div(class: [VARIANTS[@variant][:wrapper], @attributes[:class]].compact.join(' ').presence, **@attributes.except(:class)) do
      label(id: label_id, for: @id, class: [VARIANTS[@variant][:label], @label_class].compact.join(' ')) do
        plain @label
        render_marker
      end
      p(id: hint_id, class: 'text-sm text-tertiary mt-0 mb-1') { @hint } if @hint
      yield(self)
    end
  end

  def label_id = "#{@id}_label"

  # Pass to the control as aria-describedby; nil without a hint.
  def hint_id = ("#{@id}_hint" if @hint)

  private

  def render_marker
    case @required
    when true then span(class: 'req text-secondary-strong font-extra-bold', aria_hidden: 'true') { '*' }
    when false then span(class: 'opt text-tertiary font-semibold text-sm') { t('components.field.optional') }
    end
  end
end
