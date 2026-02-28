# frozen_string_literal: true

class Components::FullWidthAction < Components::Base
  COLOR_CLASSES = {
    'blue' => 'full_width_action--blue',
    'cream' => 'full_width_action--cream',
    'green' => 'full_width_action--green',
    'red' => 'full_width_action--red'
  }.freeze

  prop :title, String
  prop :link_text, String
  prop :link_url, String
  prop :color, String

  def view_template(&)
    section(class: "full_width_action #{COLOR_CLASSES[@color]}") do
      div(class: 'max_width') do
        h3(class: 'full_width_action__title') { @title }
        p(class: 'full_width_action__content', &)
        div(class: 'full_width_action__btn') do
          btn_class = @color == 'cream' ? 'link_btn_lrg link_btn_lrg--green' : 'link_btn_lrg link_btn_lrg--light'
          a(href: @link_url, class: btn_class) { @link_text }
        end
      end
    end
  end
end
