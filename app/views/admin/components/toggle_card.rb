# frozen_string_literal: true

class Views::Admin::Components::ToggleCard < Views::Admin::Components::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(form:, attribute:, title:, description: nil, variant: :success)
    @form = form
    @attribute = attribute
    @title = title
    @description = description
    @variant = variant
  end

  def view_template
    label(class: "flex items-center gap-3 p-4 rounded-lg border border-base-300 bg-base-100 cursor-pointer transition-colors #{checked_border_class}") do
      raw @form.check_box(@attribute, class: "checkbox checkbox-#{@variant}")
      div do
        p(class: 'font-medium') { @title }
        p(class: 'text-sm text-gray-600') { @description } if @description.present?
      end
    end
  end

  private

  def checked_border_class
    case @variant
    when :success then 'has-[:checked]:border-success has-[:checked]:bg-success/10'
    when :warning then 'has-[:checked]:border-warning has-[:checked]:bg-warning/10'
    when :error then 'has-[:checked]:border-error has-[:checked]:bg-error/10'
    else 'has-[:checked]:border-primary has-[:checked]:bg-primary/10'
    end
  end
end
