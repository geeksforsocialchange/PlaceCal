# frozen_string_literal: true

# One labelled form control with its required marker, hint and character counter.
# The block renders the control with `f.aria`, which ties it to them: `Field(...) { |f| form.input_field(:x, **f.aria) }`.
class Components::Admin::Field < Components::Admin::Base
  prop :for, String
  prop :label, String
  prop :hint, _Nilable(String), default: nil
  prop :required, _Boolean, default: false
  # The maximum length, shown as "12 / 200" beside the hint. The control needs the char-counter input target and action.
  prop :counter, _Nilable(Integer), default: nil
  # The larger label and hint of the step-by-step wizards.
  prop :prominent, _Boolean, default: false
  prop :attributes, Hash, :**

  def view_template(&)
    fieldset(class: ['fieldset', @attributes[:class]].compact.join(' '), **counter_controller, **@attributes.except(:class)) do
      label(for: @for, class: ['fieldset-legend', ('text-base font-semibold' if @prominent)].compact.join(' ')) do
        plain @label
        if @required
          whitespace
          span(class: 'text-error', aria_hidden: 'true') { t('admin.labels.required') }
        end
      end
      yield(self)
      render_hint
      @after&.call
    end
  end

  def aria
    { 'aria-describedby': described_by.presence, 'aria-required': ('true' if @required) }.compact
  end

  # Content that belongs under the hint, such as a check's result.
  def after(&block)
    @after = block
  end

  private

  def described_by
    [(hint_id if @hint), (counter_id if @counter)].compact.join(' ')
  end

  def hint_id = "#{@for}-hint"
  def counter_id = "#{@for}-counter"

  def render_hint_text
    css = @prominent ? ['text-sm text-gray-600', ('mt-2' unless @counter)].compact.join(' ') : 'fieldset-label'
    p(id: hint_id, class: css) { @hint.html_safe? ? raw(@hint) : plain(@hint) }
  end

  def counter_controller
    @counter ? { data: { controller: 'char-counter', char_counter_max_value: @counter } } : {}
  end

  def render_hint
    return unless @hint || @counter
    return render_hint_text unless @counter

    div(class: "flex items-center justify-between #{@prominent ? 'mt-2' : 'mt-1'}") do
      render_hint_text if @hint
      span(id: counter_id, class: 'text-xs tabular-nums transition-colors ml-auto',
           data: { char_counter_target: 'counter' }) { "0 / #{@counter}" }
    end
  end
end
