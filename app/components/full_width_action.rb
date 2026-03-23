# frozen_string_literal: true

class Components::FullWidthAction < Components::Base
  COLOR_CLASSES = {
    'blue' => 'bg-home-blue',
    'cream' => 'bg-home-background-3',
    'green' => 'bg-home-green',
    'red' => 'bg-base-secondary'
  }.freeze

  prop :title, String
  prop :link_text, String
  prop :link_url, String
  prop :color, String

  def view_template(&)
    section(class: "rounded-panel py-12 px-4 #{COLOR_CLASSES.fetch(@color, 'bg-base-secondary')}") do
      div(class: 'max-w-content mx-auto') do
        h3(class: 'text-[1.8rem] tp:text-[2.2rem] font-normal mx-auto mb-4 text-center') { @title }
        p(class: 'text-[1.3rem] mx-auto mb-12 text-center', &)
        div(class: 'w-max mx-auto') do
          btn_base = 'rounded-pill font-bold outline-offset-2 py-1 px-6 text-center no-underline whitespace-nowrap transition-[300ms] hover:bg-base-text hover:text-home-background hover:outline-base-text'
          btn_variant = @color == 'cream' ? 'bg-home-green outline outline-2 outline-home-green' : 'bg-home-background outline outline-2 outline-home-background'
          a(href: @link_url, class: "#{btn_base} #{btn_variant}") { @link_text }
        end
      end
    end
  end
end
