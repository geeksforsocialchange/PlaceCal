# frozen_string_literal: true

module Admin
  class FieldsetComponent < ViewComponent::Base
    renders_one :input

    def initialize(label:, hint: nil, required: false, char_counter: nil)
      super()
      @label = label
      @hint = hint
      @required = required
      @char_counter = char_counter
    end

    attr_reader :label, :hint, :required, :char_counter

    def required?
      @required
    end

    def char_counter?
      @char_counter.present?
    end
  end
end
