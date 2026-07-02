# frozen_string_literal: true

class Components::Join::FeatureCard < Components::Join::Base
  prop :title, String
  prop :body, String

  def view_template
    div(class: 'bg-home-background border-2 border-rules rounded-card p-5') do
      h3(class: 'font-serif font-regular text-lg text-foreground mb-1') { @title }
      p(class: 'text-detail text-tertiary leading-relaxed') { @body }
    end
  end
end
