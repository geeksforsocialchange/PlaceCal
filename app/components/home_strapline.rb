# frozen_string_literal: true

class Components::HomeStrapline < Components::Base
  def view_template
    div(class: 'home__strapline') do
      div(class: 'max_width') do
        h2(class: 'home__strapline-quote') do
          'PlaceCal is an online calendar which lists events and activities by and for members of local communities, curated around interests and locality.'
        end
      end
    end
  end
end
