# frozen_string_literal: true

# app/controllers/sites_controller.rb
class SitesController < ApplicationController
  before_action :set_primary_neighbourhood, only: [:site]
  before_action :set_site, only: [:index]
  before_action :set_places_to_get_computer_access, only: [:index]
  before_action :set_places_with_free_wifi, only: [:index]

  def index
    # A theme registered by an extension may supply its own homepage view
    # (#3368, D3); otherwise core's existing behaviour applies.
    view_class = Current.theme.homepage_view_class

    if view_class
      render view_class.new(site: @site)
    else
      render Views::Sites::Default.new(
        site: @site, places_to_get_computer_access: @places_to_get_computer_access,
        places_with_free_wifi: @places_with_free_wifi,
        region_tags: region_tags, selected_region: current_region
      )
    end
  end

  private

  # The homepage help cards honour the region control above them (#3368 D7):
  # a selected region is a Partnership tag, the same filter the partner index
  # applies (PartnersController#render_local_index).
  def set_places_to_get_computer_access
    @places_to_get_computer_access = homepage_partners('computers')
  end

  def set_places_with_free_wifi
    @places_with_free_wifi = homepage_partners('wifi')
  end

  def homepage_partners(tag_slug)
    PartnersQuery.new(site: current_site).call(tag_slug: tag_slug, partnership_id: current_region&.id)
  end
end
