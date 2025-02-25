# frozen_string_literal: true

class AdminIndexComponent < ViewComponent::Base
  def initialize(additional_links:, default: [])
    super
    @additional_links = additional_links
    @default = default
  end

  def model_name
    properties[:model].to_s.chop.humanize
  end
end
