# frozen_string_literal: true

class Views::Admin::Components::EmptyState < Views::Admin::Components::Base
  def initialize(icon:, message:, hint: nil, icon_size: '10', padding: 'py-8')
    @icon_name = icon
    @message = message
    @hint = hint
    @icon_size = icon_size
    @padding = padding
  end

  def view_template
    div(class: "text-center #{@padding}") do
      icon(@icon_name, size: @icon_size, css_class: 'mx-auto text-base-content/20', stroke_width: '1.5')
      p(class: 'mt-3 text-gray-600') { @message }
      p(class: 'text-sm text-gray-500 mt-1') { @hint } if @hint.present?
    end
  end
end
