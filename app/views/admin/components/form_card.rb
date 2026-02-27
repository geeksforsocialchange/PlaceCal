# frozen_string_literal: true

class Views::Admin::Components::FormCard < Views::Admin::Components::Base
  def initialize(icon:, title:, description: nil, fit_height: false)
    @icon_name = icon
    @title = title
    @description = description
    @fit_height = fit_height
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
