# frozen_string_literal: true

class HeroComponent < ViewComponent::Base
  def initialize(title, subtitle = '', schema = nil)
    super
    @title = clean_title(title)
    @subtitle = subtitle
    @schema = schema
  end

  def clean_title(title)
    if title.length > 32
      title.split.in_groups(2, false).map { |g| g.join(' ') }.join('<br> ').html_safe # rubocop:disable Rails/OutputSafety
    else
      title
    end
  end
end
