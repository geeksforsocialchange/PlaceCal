# frozen_string_literal: true

class AudienceIntroComponent < ViewComponent::Base
  attr_reader :title
  attr_reader :subtitle
  attr_reader :image
  attr_reader :image_alt
  
  def initialize(title:, subtitle: nil, image:, image_alt:)
    @title = title
    @subtitle = subtitle
    @image = image
    @image_alt = image_alt
    @content = yield if block_given?
  end
end
