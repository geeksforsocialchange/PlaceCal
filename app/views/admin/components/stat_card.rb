# frozen_string_literal: true

class Views::Admin::Components::StatCard < Views::Admin::Components::Base
  def initialize(label:, value:, icon: nil, subtitle: nil)
    @label = label
    @value = value
    @icon_name = icon
    @subtitle = subtitle
  end

  def view_template(&block)
    div(class: 'card bg-base-100 border border-base-300 shadow-sm') do
      div(class: 'card-body p-3') do
        div(class: 'flex items-center justify-between') do
          span(class: 'text-xs text-gray-600') { @label }
          if @subtitle
            span(class: 'text-xs text-gray-500') { @subtitle }
          elsif @icon_name
            icon(@icon_name, size: '4', css_class: 'text-gray-400')
          end
        end
        div(class: 'text-2xl font-bold text-base-content') { @value.to_s }
        yield if block
      end
    end
  end
end
