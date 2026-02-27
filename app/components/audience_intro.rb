# frozen_string_literal: true

class Components::AudienceIntro < Components::Base
  prop :title, String
  prop :subtitle, String
  prop :image, String
  prop :image_alt, String

  def view_template(&)
    div(class: 'card card--first center') do
      h1(class: 'section') { @title }
    end

    div(class: 'card card--plain audience pattern pattern--audience reveal', data: { controller: 'reveal' }) do
      div(class: 'reveal__teaser') do
        h2(class: 'center alt-title') { raw(safe(@subtitle)) }
        div(class: 'audience__photo') do
          image_tag("home/audiences/#{@image}", alt: @image_alt)
        end
      end
      div(class: 'audience__body', &)
      div(class: 'center') do
        link_to('Our story', helpers.our_story_path, class: 'btn btn--big btn--home-3')
        link_to('See it in action', helpers.find_placecal_path, class: 'btn btn--big btn--home-3')
      end
      button(class: 'reveal__button', data: { reveal_target: 'button', action: 'click->reveal#toggle' }) do
        'Open to read more'
      end
    end
  end
end
