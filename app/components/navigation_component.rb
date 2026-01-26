# frozen_string_literal: true

class NavigationComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(navigation:, site: nil)
    super()
    @navigation = navigation
    @site = site
  end

  attr_reader :navigation, :site
end
