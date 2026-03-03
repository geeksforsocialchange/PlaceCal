# frozen_string_literal: true

class Components::Audience < Components::Base
  prop :title, String
  prop :image, String
  prop :image_alt, String
  prop :body, String
  prop :link, _Nilable(String), default: nil

  def view_template
    div(class: 'card card--split card--audience') do
      div(class: 'card__title') do
        h3(class: 'small') { @title }
      end
      div(class: 'card__body') do
        image_tag(@image, alt: @image_alt, class: 'card--audience__image')
        p(class: 'small') { @body }
      end
    end
  end
end
