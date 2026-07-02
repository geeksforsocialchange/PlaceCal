# frozen_string_literal: true

class Components::Join::FeatureCard < Components::Join::Base
  prop :title, String
  prop :body, String
  # 3 under a section h2 (homepage, audience pages); 2 when the card grid sits
  # directly under the page h1 (features index) — heading order must not skip.
  prop :heading_level, Integer, default: 3

  def view_template
    div(class: 'bg-home-background border-2 border-rules rounded-card p-5') do
      send(:"h#{@heading_level}", class: 'font-serif font-regular text-lg text-foreground mt-0 mb-1.5') { @title }
      p(class: 'text-detail text-tertiary leading-relaxed m-0') { @body }
    end
  end
end
