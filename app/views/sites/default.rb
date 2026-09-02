# frozen_string_literal: true

class Views::Sites::Default < Views::Base
  prop :site, Site, reader: :private
  prop :places_to_get_computer_access, ActiveRecord::Relation, reader: :private
  prop :places_with_free_wifi, ActiveRecord::Relation, reader: :private
  prop :region_tags, Array, reader: :private, default: -> { [] }
  prop :selected_region, _Nilable(::Tag), reader: :private, default: nil

  def view_template
    content_for(:description) { site.og_description }

    HeroSection(
      image_path: site.hero_image.url,
      image_credit: site.hero_image_credit,
      title: site.hero_text,
      alttext: site.hero_alttext
    )

    render_region_filter
    render_mission
    render_about
    render_support
  end

  private

  # A site with more than one Partnership tag offers the region filter on its
  # homepage too (#3368 D7); the choice then travels through the site nav.
  def render_region_filter
    return if region_tags.size < 2

    section(class: 'region') do
      div(class: 'container-public') do
        RegionFilter(tags: region_tags, selected: selected_region)
      end
    end
  end

  def render_mission
    section(class: 'region region__mission') do
      div(class: 'container-narrow') do
        p do
          plain "We're working with "
          link_to 'local organisations', partners_path
          plain " to create a great calendar of everything that's on in #{site.place_name}."
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
      div(class: 'container-narrow first-ele-h3-serif') do
        raw safe(site.description_html.to_s)
        Profile(user: site.site_admin) if site.site_admin.present?
      end
    end
  end

  def render_support
    section(class: 'region region__support') do
      div(class: 'container-public') do
        div(class: 'gr gr--3') do
          div { HelpCard(variant: :adding_events, site: site) }
          div { HelpCard(places: places_to_get_computer_access, variant: :computer_access) } if places_to_get_computer_access.present?
          div { HelpCard(places: places_with_free_wifi, variant: :free_wifi) } if places_with_free_wifi.present?
          div { HelpCard(variant: :getting_help) }
        end
      end
    end
  end
end
