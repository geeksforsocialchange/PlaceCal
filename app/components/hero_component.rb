# frozen_string_literal: true

class HeroComponent < ViewComponent::Base
  def initialize(title, subtitle = '', schema = nil)
    super
    @title = title.length > 32 ? title.split.in_groups(2, false).map { |g| g.join(' ') }.join('<br> ').html_safe : title # rubocop:disable Rails/OutputSafety
    @subtitle = subtitle
    @schema = schema
  end
end
