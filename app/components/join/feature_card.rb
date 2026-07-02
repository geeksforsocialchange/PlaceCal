# frozen_string_literal: true

class Components::Join::FeatureCard < Components::Join::Base
  prop :title, String
  prop :body, String

  def view_template
    div(class: 'bg-home-background border-2 border-rules rounded-card p-5') do
      h3(class: 'font-serif font-regular text-lg text-foreground mt-0 mb-1.5') { @title }
      p(class: 'text-detail text-tertiary leading-relaxed m-0') { @body }
    end
  end
end
