# frozen_string_literal: true

class HomeFooterPreview < Lookbook::Preview
  # @label Default
  def default
    render Components::HomeFooter.new
  end
end
