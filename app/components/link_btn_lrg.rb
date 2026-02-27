# frozen_string_literal: true

class Components::LinkBtnLrg < Components::Base
  prop :link_url, String
  prop :color, String

  def after_initialize
    @color =
      case @color
      when 'green' then 'link_btn_lrg--green'
      when 'pink' then 'link_btn_lrg--pink'
      else 'link_btn_lrg--light'
      end
  end

  def view_template(&)
    a(href: @link_url, class: "link_btn_lrg #{@color}", &)
  end
end
