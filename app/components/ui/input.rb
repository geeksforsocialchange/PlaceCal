# frozen_string_literal: true

class Components::UI::Input < Components::Base
  # The form-control box, shared with UI::Select's trigger.
  BOX = 'w-full h-(--height-field) border-2 border-rules rounded-sm px-4 text-sm bg-background text-foreground transition-colors'

  prop :type, String, default: 'text'
  # Adds a Show/Hide button to a password field.
  prop :reveal, _Boolean, default: false
  prop :attributes, Hash, :**

  def view_template
    return render_input unless @reveal

    div(class: 'relative', data: { controller: 'password-reveal', **reveal_values }) do
      render_input('pr-12', password_reveal_target: 'input')
      button(
        type: 'button', hidden: true,
        class: 'absolute inset-y-0 right-0 px-3 flex items-center text-tertiary hover:text-foreground cursor-pointer',
        aria: { controls: @attributes[:id], label: t('components.password_reveal.show_label') },
        data: { password_reveal_target: 'button', action: 'password-reveal#toggle' }
      ) do
        span(data: { password_reveal_target: 'showIcon' }) { raw(view_context.icon(:eye, size: nil, css_class: 'size-5')) }
        span(hidden: true, data: { password_reveal_target: 'hideIcon' }) { raw(view_context.icon(:eye_off, size: nil, css_class: 'size-5')) }
      end
      span(class: 'sr-only', aria: { live: 'polite' }, data: { password_reveal_target: 'status' })
    end
  end

  private

  def render_input(extra_class = nil, **data)
    input(type: @type, class: [BOX, 'outline-none focus:border-foreground', extra_class, @attributes[:class]].compact.join(' '),
          **@attributes.except(:class, :data), data: { **@attributes.fetch(:data, {}), **data })
  end

  def reveal_values
    %i[show_label hide_label shown hidden].to_h do |key|
      [:"password_reveal_#{key}_value", t("components.password_reveal.#{key}")]
    end
  end
end
