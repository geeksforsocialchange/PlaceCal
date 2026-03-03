# frozen_string_literal: true

class Views::Sites::Mossley < Views::Base
  prop :site, _Any, reader: :private
  prop :places_to_get_online, _Nilable(_Any), reader: :private

  def view_template
    content_for(:title) { site.name }
    content_for(:image) { image_url('regions/mossley/og.png') }

    render_hero
    render_mission
    render_about
    render_support
  end

  private

  def render_hero
    section do
      div(class: 'hero_image hero_image--mossley')
    end

    section(class: 'region region__title--mossley') do
      div(class: 'c c--narrowish') do
        h1 { 'Marvellous Mossley celebrates our town and lets people know about all the community activity happening here.' }
      end
    end
  end

  def render_mission # rubocop:disable Metrics/AbcSize
    section(class: 'region region__mission') do
      div(class: 'c c--narrow') do
        p { 'There are around 40 groups, mostly volunteer led, offering an amazing amount of activities at a variety of locations in our little town. Marvellous Mossley is a platform to bring all of this together in one place through this website and also the printed Mossley Missive.' }
        p { 'We coordinate an annual celebration event and the great Mossley Mammoth Hunt along with other initiatives such as the Marvellous Mossley Pebble Dash. The project relies on ongoing grant funding to continue.' }
        p do
          plain "We're working with "
          link_to 'local organisations', partners_path
          plain ' and '
          link_to 'places', places_path
          plain " to create a great calendar of everything that's on in #{site.name}."
        end
        link_to "See what's on", events_path, class: 'btn btn--lg btn--alt btn--mt'
      end
    end
  end

  def render_about
    section(class: 'region region__management') do
      div(class: 'title-strip') do
        h2(class: 'h2--alt') { 'About Us' }
      end
      div(class: 'c c--narrow first-ele-h3') do
        p { "If you're a local organisation and want to join our network, get in touch below." }
        p { 'We provide training and support to help you publish your events and promote your activities.' }
        raw site.description_html.to_s.html_safe # rubocop:disable Rails/OutputSafety
        render(Components::Profile.new(user: site.site_admin)) if site.site_admin.present?
      end
    end
  end

  def render_support
    section(class: 'region region__support') do
      div(class: 'c') do
        div(class: 'g') do
          div(class: 'gi gi__1-3') do
            render(Components::HelpCard.new(variant: :adding_events, site: site))
          end
          div(class: 'gi gi__1-3') do
            render(Components::HelpCard.new(places: places_to_get_online, variant: :computer_access))
          end
          div(class: 'gi gi__1-3') do
            render(Components::HelpCard.new(variant: :getting_help))
          end
        end
      end
    end
  end
end
