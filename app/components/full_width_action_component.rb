# frozen_string_literal: true

class FullWidthActionComponent < ViewComponent::Base
  def initialize(title:, link_text:, link_url:, color:)
    super
    @title = title
    @link_text = link_text
    @link_url = link_url
    @color = color
    @color_class = {
      'blue' => 'full_width_action--blue',
      'cream' => 'full_width_action--cream',
      'green' => 'full_width_action--green',
      'red' => 'full_width_action--red'
    }
  end
end
