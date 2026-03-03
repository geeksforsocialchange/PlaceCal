# frozen_string_literal: true

class Views::Pages::Home < Views::Base
  prop :neighbourhoods, _Interface(:each), reader: :private

  def view_template
    article(class: 'home') do
      div(class: 'margin home__flow') do
        div(class: 'home__strapline') do
          div(class: 'max_width') do
            h2(class: 'home__strapline-quote') do
              'PlaceCal is an online calendar which lists events and activities by and for members of local communities, curated around interests and locality.'
            end
          end
        end
        CaseStudy(
          partner: 'The Trans Dimension',
          link_url: '/find-placecal',
          logo_src: 'home/logos/tdd_logo.svg',
          image_alt: 'trans dimension illustration',
          image_src: 'home/case-studies/trans-dimension-illustration.png',
          partner_url: 'https://transdimension.uk/',
          pull_quote: 'We see and experience the barriers in place for trans, non-binary, and gender diverse people trying to meet, connect, and socialise and know that for disabled trans people the challenge is even harder.',
          description: [
            'The Trans Dimension is an online community hub connecting trans communities in London. It collates news, events and services by and for trans people, and is built using PlaceCal.',
            'The Trans Dimension is run by Geeks for Social Change in partnership with Gendered Intelligence with support from the Comic Relief Tech for Good programme. At this stage, the Trans Dimension is focussed on London-based events listings only, however we do plan to expand to cover more areas across the UK.'
          ]
        )
        div(class: 'container-with-header') do
          div(class: 'container-with-header__head container-with-header__head--green') do
            h3(class: 'container-with-header__title') { 'Place-based calendars' }
          end
          div(class: 'container-with-header__body') do
            ul(class: 'four_col_grid') do
              neighbourhoods.take(4).each do |site|
                NeighbourhoodHomeCard(site: site)
              end
            end
          end
        end
        FullWidthAction(title: 'Find your PlaceCal', link_text: 'See calendars', link_url: find_placecal_path, color: 'red') do
          plain 'Ready to get started with PlaceCal? Here you can see a list of all current PlaceCal instances, organised by interest and location.'
        end
        FullWidthAction(title: 'Want to create a PlaceCal for your community?', link_text: 'Get in touch', link_url: get_in_touch_path, color: 'green') do
          plain 'Work with us to set up a PlaceCal for your community, built through on-the-ground connections with venues, organisers, and community members.'
        end
        FullWidthAction(title: 'How did PlaceCal start?', link_text: 'Learn more', link_url: our_story_path, color: 'cream') do
          plain 'We wanted to examine the causes of social isolation and loneliness within communities in order to figure out how to combat them.'
        end
      end
    end
  end
end
