# frozen_string_literal: true

class Views::Pages::FindPlacecal < Views::Base
  prop :neighbourhoods, _Interface(:each), reader: :private
  prop :partnerships, _Interface(:each), reader: :private

  def view_template
    article(class: 'home') do
      div(class: 'margin') do
        div(class: 'card card--first center') do
          h1(class: 'section') { 'Find your PlaceCal' }
          p(class: 'alt-title-small') { "Here's a list of all PlaceCal instances, organised by interest and location." }
        end
        div(class: 'featured_partnerships') do
          h3(class: 'featured_partnerships--title') { 'Curated Calendars' }
          ul(class: 'four_col_grid--larger') do
            partnerships.each do |site|
              render Components::PartnershipCard.new(site: site)
            end
          end
        end
        div(class: 'container-with-header') do
          div(class: 'container-with-header__head container-with-header__head--green') do
            h3(class: 'container-with-header__title') { 'Place-based calendars' }
          end
          div(class: 'container-with-header__body') do
            ul(class: 'four_col_grid') do
              neighbourhoods.each do |site|
                render Components::NeighbourhoodHomeCard.new(site: site)
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
