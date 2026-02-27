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
      MaxWidth do
        h3(class: 'full_width_action__title') { @title }
        p(class: 'full_width_action__content', &)
        div(class: 'full_width_action__btn') do
          btn_color = @color == 'cream' ? 'green' : ''
          LinkBtnLrg(link_url: @link_url, color: btn_color) do
            @link_text
          end
        end
      end
    end
  end
end
