# frozen_string_literal: true

class ImpactStoryComponent < ViewComponent::Base
  def initialize(title:, image:, image_caption:)
    super
    @title = title
    @image = image
    @image_caption = image_caption
  end

  attr_reader :title, :image, :image_caption
end
