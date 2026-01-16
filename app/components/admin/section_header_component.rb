# frozen_string_literal: true

module Admin
  class SectionHeaderComponent < ViewComponent::Base
    renders_one :icon

    def initialize(title:, description: nil, tag: :h2, margin: 6)
      super()
      @title = title
      @description = description
      @tag = tag
      @margin = margin
    end

    private

    attr_reader :title, :description, :tag, :margin

    def header_classes
      base = 'text-lg font-bold mb-1'
      icon? ? "#{base} flex items-center gap-2" : base
    end

    def description_classes
      "text-sm text-base-content/60 mb-#{margin}"
    end
  end
end
