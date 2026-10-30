# frozen_string_literal: true

class Components::Join::FeatureCard < Components::Join::Base
  prop :title, String
  prop :body, String
  # 2 when the grid sits directly under the page h1, so heading order never skips.
  prop :heading_level, Integer, default: 3

  def view_template
    UI::Card() do
      UI::Heading(level: @heading_level, size: :item, spacing: :xs) { @title }
      UI::Text(variant: :lede, tone: :muted, spacing: :none) { @body }
    end
  end
end
