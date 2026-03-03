# frozen_string_literal: true

class Components::Admin::FormCard < Components::Admin::Base
  prop :icon, Symbol
  prop :title, String
  prop :description, _Nilable(String), default: nil
  prop :fit_height, _Boolean, default: false

  def after_initialize
    @icon_name = @icon
  end

  def view_template(&block)
    classes = 'card bg-base-200/50 border border-base-300'
    classes += ' h-fit' if @fit_height
    div(class: classes) do
      div(class: 'card-body p-4 gap-3') do
        h2(class: 'font-semibold flex items-center gap-2 text-base') do
          icon(@icon_name, size: '4')
          plain @title
        end
        p(class: 'text-xs text-gray-600') { @description } if @description.present?
        yield if block
      end
    end
  end
end
