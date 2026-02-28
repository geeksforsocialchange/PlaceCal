# frozen_string_literal: true

class Components::Admin::RadioCardGroup < Components::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder
  prop :attribute, Symbol
  prop :values, Array
  prop :i18n_scope, _Nilable(String), default: nil

  def view_template
    div(class: 'space-y-3') do
      @values.each do |value|
        label(class: 'flex items-start gap-3 p-3 rounded-lg border border-base-300 bg-base-100 hover:bg-base-200/50 cursor-pointer transition-colors has-[:checked]:border-placecal-orange has-[:checked]:bg-orange-50/50') do
          raw(@form.radio_button(@attribute, value, class: 'radio radio-warning mt-0.5'))
          span(class: 'text-sm leading-relaxed') { label_for(value) }
        end
      end
    end
  end

  private

  def model_class
    @form.object.class
  end

  def label_for(value)
    name = model_class.human_attribute_name("#{@attribute}.#{value}")
    description = @i18n_scope ? I18n.t("#{@i18n_scope}.#{value}", default: nil) : nil

    if description
      safe_join([view_context.tag.strong(name), ': ', description])
    else
      name
    end
  end
end
