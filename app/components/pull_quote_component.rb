# frozen_string_literal: true

class PullQuoteComponent < ViewComponent::Base
  def initialize(source:, context:, options:)
    super
    @context = context
    @source = source
    @color_mode = options[:light_mode] ? 'light' : 'dark'
  end
end
