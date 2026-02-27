# frozen_string_literal: true

class Components::Admin::Error < Components::Admin::Base
  prop :object, _Any, :positional

  def view_template
    return unless @object.errors.any?

    div(id: 'form-errors', role: 'alert', class: 'alert alert-error mb-3 shadow-lg items-start') do
      icon(:warning, size: '6', css_class: 'shrink-0 mt-0.5')
      div do
        h3(class: 'font-bold') do
          t('activerecord.errors.template.header', count: @object.errors.count, model: @object.class.model_name.human)
        end
        ul(class: 'mt-2 ml-3 text-sm list-disc list-inside space-y-0.5') do
          @object.errors.full_messages.each do |message|
            li { message }
          end
        end
      end
    end
  end
end
