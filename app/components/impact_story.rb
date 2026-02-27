# frozen_string_literal: true

class Components::ImpactStory < Components::Base
  prop :title, String
  prop :image, String
  prop :image_caption, String

  def view_template(&)
    div(class: 'card__body') do
      h3(class: 'alt-title-small center') { @title }
      figure do
        image_tag(@image, class: 'rounded')
        figcaption { @image_caption }
      end
      div(class: 'impact__cols', &)
    end
  end
end
