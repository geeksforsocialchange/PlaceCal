# frozen_string_literal: true

class Views::Pages::FindPlacecal < Views::Base
  prop :neighbourhoods, _Interface(:each), reader: :private
  prop :partnerships, _Interface(:each), reader: :private

  def view_template
    article(class: 'home') do
      div(class: 'mx-3 tp:mx-6') do
        div(class: 'card card--first center') do
          h1(class: 'section') { 'Find your PlaceCal' }
          p(class: 'alt-title-small') { "Here's a list of all PlaceCal instances, organised by interest and location." }
        end
        div(class: 'mb-8') do
          h3(class: 'text-home-background-3 font-sans text-[1.8rem] tp:text-[2.2rem] font-normal mx-auto my-8 max-w-[25ch] text-center') { 'Curated Calendars' }
          ul(class: 'grid gap-y-8 gap-x-4 grid-cols-[repeat(auto-fit,minmax(clamp(16rem,calc(25%-1rem),18rem),1fr))] tp:grid-cols-[repeat(auto-fit,minmax(clamp(14.5rem,calc(25%-1rem),18rem),1fr))] list-none m-0 p-0 dt:px-8') do
            partnerships.each do |site|
              PartnershipCard(site: site)
            end
          end
        end
        div(class: 'grid grid-cols-1 grid-rows-[auto_2rem_auto]') do
          div(class: 'bg-home-green rounded-t-[1.11rem] col-start-1 col-end-2 row-start-1 row-end-3 pt-6 px-4 pb-14') do
            h3(class: 'text-[1.8rem] tp:text-[2.2rem] font-normal mx-auto max-w-[25ch] text-center') { 'Place-based calendars' }
          end
          div(class: 'bg-home-background rounded-[1.11rem] col-start-1 col-end-2 row-start-2 row-end-4 py-12 px-4') do
            ul(class: 'grid gap-y-8 gap-x-4 grid-cols-[repeat(auto-fit,minmax(clamp(13rem,calc(25%-1rem),15rem),1fr))] list-none m-0 p-0 dt:px-8') do
              neighbourhoods.each do |site|
                NeighbourhoodHomeCard(site: site)
              end
            end
          end
        end
        div(class: 'card card--alt center card--learn-how') do
          h2(class: 'fc-text') { 'Set up PlaceCal in your community' }
          link_to 'Get in touch', get_in_touch_path, class: 'btn btn--big btn--home-2'
        end
      end
    end
  end
end
