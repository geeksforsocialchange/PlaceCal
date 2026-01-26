# frozen_string_literal: true

class NavigationComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(navigation:)
    super
    @navigation = navigation
  end

  attr_reader :navigation
end
