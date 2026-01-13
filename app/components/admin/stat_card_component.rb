# frozen_string_literal: true

module Admin
  class StatCardComponent < ViewComponent::Base
    def initialize(label:, value:, icon: nil, subtitle: nil)
      super
      @label = label
      @icon = icon
      @value = value
      @subtitle = subtitle
    end
  end
end
