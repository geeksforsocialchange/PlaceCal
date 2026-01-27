# frozen_string_literal: true

class AudienceComponent < ViewComponent::Base
  def initialize(title:, image:, image_alt:, body:, link: nil)
    super()
    @title = title
    @image = image
    @image_alt = image_alt
    @body = body
    @link = link
  end

  attr_reader :title, :image, :image_alt, :body, :link
end
