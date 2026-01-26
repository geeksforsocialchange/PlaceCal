# frozen_string_literal: true

class AudienceIntroComponent < ViewComponent::Base
  def initialize(title:, subtitle:, image:, image_alt:)
    super
    @title = title
    @subtitle = subtitle
    @image = image
    @image_alt = image_alt
  end

  attr_reader :title, :subtitle, :image, :image_alt
end
