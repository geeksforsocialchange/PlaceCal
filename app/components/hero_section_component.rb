# frozen_string_literal: true

class HeroSectionComponent < ViewComponent::Base
  def initialize(image_path:, image_credit:, title:, alttext:)
    super
    @title = title.presence || I18n.t('meta.description', site: 'PlaceCal')
    @image_path = image_path
    @alttext = alttext
    @image_credit = image_credit
  end
end
