# frozen_string_literal: true

class Components::UI::Input < Components::Base
  # The form-control box, shared with UI::Select's trigger.
  BOX = 'w-full h-(--height-field) border-2 border-rules rounded-sm px-4 text-sm bg-background text-foreground transition-colors'

  prop :type, String, default: 'text'
  prop :attributes, Hash, :**

  def view_template
    input(type: @type, class: [BOX, 'outline-none focus:border-foreground', @attributes[:class]].compact.join(' '),
          **@attributes.except(:class))
  end
end
