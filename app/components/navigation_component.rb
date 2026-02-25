# frozen_string_literal: true

class NavigationComponent < ViewComponent::Base
  include ApplicationHelper
  include SvgIconsHelper
  include SvgImagesHelper

  def initialize(navigation:, site: nil)
    super()
    @navigation = navigation
    @site = site
    # rubocop:disable Style/SafeNavigationChainLength
    @logo_path = site&.logo&.to_s&.sub(%r{^/uploads/}, '')
    # rubocop:enable Style/SafeNavigationChainLength
  end

  attr_reader :navigation, :site
end
