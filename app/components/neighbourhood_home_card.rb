# frozen_string_literal: true

class Components::NeighbourhoodHomeCard < Components::Base
  prop :site, _Any

  def view_template
    li(class: 'neighbourhood_home_card') do
      img(
        'aria-hidden': 'true',
        class: 'neighbourhood_home_card__image',
        src: @site.hero_image&.url,
        alt: ''
      )
      h4(class: 'neighbourhood_home_card__name') { @site.place_name }
      hr(class: 'neighbourhood_home_card__rule')
      link_to(
        "#{@site.place_name} calendar",
        "#{helpers.root_url(subdomain: @site.slug)}events",
        class: 'neighbourhood_home_card__link'
      )
    end
  end
end
