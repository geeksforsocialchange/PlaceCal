# frozen_string_literal: true

module Admin
  class ToggleCardComponent < ViewComponent::Base
    def initialize(form:, attribute:, title:, description: nil, variant: :success)
      super()
      @form = form
      @attribute = attribute
      @title = title
      @description = description
      @variant = variant
    end

    private

    attr_reader :form, :attribute, :title, :description, :variant

    def checkbox_class
      "checkbox checkbox-#{variant}"
    end

    def checked_border_class
      case variant
      when :success then 'has-[:checked]:border-success has-[:checked]:bg-success/10'
      when :warning then 'has-[:checked]:border-warning has-[:checked]:bg-warning/10'
      when :error then 'has-[:checked]:border-error has-[:checked]:bg-error/10'
      else 'has-[:checked]:border-primary has-[:checked]:bg-primary/10'
      end
    end
  end
end
