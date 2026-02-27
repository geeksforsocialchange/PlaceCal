# frozen_string_literal: true

class Views::Admin::Components::InfoCard < Views::Admin::Components::Base
  COLORS = {
    orange: { bg: 'bg-placecal-orange/10', text: 'text-placecal-orange' },
    info: { bg: 'bg-info/10', text: 'text-info' },
    success: { bg: 'bg-success/10', text: 'text-success' },
    error: { bg: 'bg-error/10', text: 'text-error' },
    warning: { bg: 'bg-warning/10', text: 'text-warning' },
    neutral: { bg: 'bg-base-300', text: 'text-base-content/30' }
  }.freeze

  def initialize(icon:, label:, value: nil, color: :orange)
    @icon_name = icon
    @label = label
    @value = value
    @color = color
  end

  def view_template(&block)
    div(class: 'card bg-base-200/50 border border-base-300') do
      div(class: 'card-body p-4') do
        div(class: 'flex items-center gap-3') do
          div(class: "w-10 h-10 rounded-lg #{icon_bg_class} flex items-center justify-center shrink-0") do
            icon(@icon_name, size: '5', css_class: icon_text_class)
          end
          div do
            p(class: 'text-xs text-gray-600 uppercase font-medium') { @label }
            if block
              yield
            elsif @value.present?
              p(class: 'font-semibold text-lg') { @value.to_s }
            else
              p(class: 'text-gray-600 italic') { 'Not set' }
            end
          end
        end
      end
    end
  end

  private

  def icon_bg_class
    COLORS.dig(@color, :bg) || COLORS[:orange][:bg]
  end

  def icon_text_class
    COLORS.dig(@color, :text) || COLORS[:orange][:text]
  end
end
