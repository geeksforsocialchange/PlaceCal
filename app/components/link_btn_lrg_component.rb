# frozen_string_literal: true

class LinkBtnLrgComponent < ViewComponent::Base
  def initialize(link_url:, color:)
    super
    @link_url = link_url
    @color =
      case color
      when 'green'
        'link_btn_lrg--green'
      when 'pink'
        'link_btn_lrg--pink'
      else
        'link_btn_lrg--light'
      end
  end
end
