# frozen_string_literal: true

class Components::Join::FeatureCard < Components::Join::Base
  register_output_helper :icon

  prop :title, String
  prop :body, String
  # 2 when the grid sits directly under the page h1, so heading order never skips.
  prop :heading_level, Integer, default: 3
  prop :icon, _Nilable(Symbol), default: nil

  def view_template
    UI::Card() do
      div(class: 'mb-3 text-secondary-strong') { icon(@icon, size: '7') } if @icon
      UI::Heading(level: @heading_level, size: :item, spacing: :xs, balance: true) { @title }
      UI::Text(variant: :lede, tone: :muted, spacing: :none, pretty: true) { @body }
    end
  end
end
