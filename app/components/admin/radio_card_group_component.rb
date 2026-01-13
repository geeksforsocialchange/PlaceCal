# frozen_string_literal: true

module Admin
  class RadioCardGroupComponent < ViewComponent::Base
    def initialize(form:, attribute:, values:, label_method: nil, include_blank: false)
      super()
      @form = form
      @attribute = attribute
      @values = values
      @label_method = label_method
      @include_blank = include_blank
    end

    private

    attr_reader :form, :attribute, :values, :label_method, :include_blank

    def label_for(value)
      return value.to_s.titleize unless label_method

      label_method.call([nil, value])
    end
  end
end
