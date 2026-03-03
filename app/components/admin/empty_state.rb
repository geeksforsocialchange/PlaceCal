# frozen_string_literal: true

class Components::Admin::EmptyState < Components::Admin::Base
  prop :icon, Symbol
  prop :message, String
  prop :hint, _Nilable(String), default: nil
  prop :icon_size, String, default: '10'
  prop :padding, String, default: 'py-8'

  def after_initialize
    @icon_name = @icon
  end

  def view_template
    div(class: "text-center #{@padding}") do
      icon(@icon_name, size: @icon_size, css_class: 'mx-auto text-base-content/20 stroke-1')
      p(class: 'mt-3 text-gray-600') { @message }
      p(class: 'text-sm text-gray-500 mt-1') { @hint } if @hint.present?
    end
  end
end
