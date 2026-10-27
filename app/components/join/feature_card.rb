# frozen_string_literal: true

class Components::Join::FeatureCard < Components::Join::Base
  prop :title, String
  prop :body, String
  # 2 when the grid sits directly under the page h1, so heading order never skips.
  prop :heading_level, Integer, default: 3

  def view_template
    UI::Card() do
      send(:"h#{@heading_level}", class: 'font-serif font-regular text-lg text-foreground mt-0 mb-1.5') { @title }
      p(class: 'text-detail text-tertiary leading-relaxed m-0') { @body }
    end
  end
end
