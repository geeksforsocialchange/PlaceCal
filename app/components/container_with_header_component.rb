# frozen_string_literal: true

class ContainerWithHeaderComponent < ViewComponent::Base
  def initialize(title:, color:)
    super
    @title = title
    @color = color
  end
end
