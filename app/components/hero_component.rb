# frozen_string_literal: true

class HeroComponent < ViewComponent::Base
  attr_reader :subtitle
  attr_reader :schema
  
  def initialize(title:, subtitle: nil, schema: nil)
    @title = title
    @subtitle = subtitle
    @schema = schema
  end
  
  def title
    s = @title
    if s.respond_to?(:length) && s.length > 32
      s.split.in_groups(2, false).map { |g| g.join(' ') }.join('<br> ').html_safe
    else
      s
    end
  end  
end
