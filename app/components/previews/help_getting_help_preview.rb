# frozen_string_literal: true

class HelpGettingHelpPreview < ViewComponent::Preview
  # @label Default
  def default
    render(HelpGettingHelp.new)
  end
end
