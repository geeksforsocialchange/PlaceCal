# frozen_string_literal: true

class Components::UI::Field < Components::Base
  theme_scope :field,
              parts: {
                required: 'The asterisk after a required field\'s label.',
                optional: 'The "optional" note after an optional field\'s label.'
              },
              tokens: %i[--color-secondary-strong --color-tertiary --font-weight-semibold --font-weight-extra-bold --text-sm]

  # Sentence-case bold label, shared with UI::Fieldset's legend.
  STRONG_LABEL = 'flex items-center gap-1.25 font-bold text-detail text-foreground'

  VARIANTS = {
    caps: { wrapper: nil, label: 'block allcaps-label text-tertiary mb-1' },
    # For a form laid out as a grid of fields
    strong: { wrapper: 'flex flex-col gap-1.5 min-w-0', label: STRONG_LABEL }
  }.freeze

  prop :label, String
  # The id of the control the label is for, or of the group when group: is true.
  prop :id, String
  prop :hint, _Nilable(String), default: nil
  prop :variant, _Union(*VARIANTS.keys), default: :caps
  # true marks the label with an asterisk, false with "optional"; nil marks nothing.
  prop :required, _Nilable(_Boolean), default: nil
  # Attributes for the label, such as a theming part.
  prop :label_attributes, Hash, default: -> { {} }
  # Labels a group of controls rather than one: the wrapper becomes the group and the label is a span that names it.
  prop :group, _Boolean, default: false
  prop :attributes, Hash, :**

  def view_template
    group = @group ? { role: 'group', aria: { labelledby: label_id } } : {}
    div(class: [VARIANTS[@variant][:wrapper], @attributes[:class]].compact.join(' ').presence, **group, **@attributes.except(:class)) do
      public_send(@group ? :span : :label, id: label_id, for: (@id unless @group), class: [VARIANTS[@variant][:label], @label_attributes[:class]].compact.join(' '),
                                           **@label_attributes.except(:class)) do
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
    when true then span(**part(:required, class: 'text-secondary-strong font-extra-bold', aria_hidden: 'true')) { '*' }
    when false then span(**part(:optional, class: 'text-tertiary font-semibold text-sm')) { t('components.field.optional') }
    end
  end
end
