# frozen_string_literal: true

class Components::NeighbourhoodHomeCard < Components::Base
  prop :site, ::Site

  def view_template
    li(class: 'flex flex-col items-center gap-2 text-base-text px-8 pb-4') do
      img(
        'aria-hidden': 'true',
        class: 'aspect-[1.25] rounded-[1.11rem] object-cover w-full',
        src: @site.hero_image&.url,
        alt: ''
      )
      h4(class: 'm-0') { @site.place_name }
      hr(class: 'border-2 my-2 w-full')
      link_to(
        "#{@site.place_name} calendar",
        "#{root_url(subdomain: @site.slug)}events",
        class: 'bg-home-green rounded-[1.11rem] text-[0.8rem] font-bold m-0 py-1 text-center no-underline whitespace-nowrap w-full transition-colors duration-300 ease-in-out hover:bg-base-text hover:text-base-background'
      )
    end
  end
end
