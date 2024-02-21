# frozen_string_literal: true

class AudienceComponent < ViewComponent::Base
  attr_reader :title
  attr_reader :image
  attr_reader :image_alt
  attr_reader :body
  attr_reader :link

  def initialize(title:, image:, image_alt:, body:, link:)
    @title = title
    @image = image
    @image_alt = image_alt
    @body = body
    @link = link
  end
  
end
