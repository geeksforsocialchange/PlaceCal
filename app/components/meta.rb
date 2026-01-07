# frozen_string_literal: true

class Meta < ViewComponent::Base
  renders_one :link
  def initialize(permalink)
    super()
    @permalink = permalink
  end
end
