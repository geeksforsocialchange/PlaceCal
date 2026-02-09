# frozen_string_literal: true

# app/controllers/sites_controller.rb
class SitesController < ApplicationController
  before_action :set_primary_neighbourhood, only: [:site]
  before_action :set_site, only: [:index]
  before_action :set_places_to_get_computer_access, only: [:index]
  before_action :set_places_with_free_wifi, only: [:index]

  def index
    if current_site.slug == 'mossley'
      render template: "sites/#{current_site.slug}"
    else
      render template: 'sites/default'
    end
  end

  private

  def set_places_to_get_computer_access
    @places_to_get_computer_access = PartnersQuery.new(site: current_site).call(tag_slug: 'computers')
  end

  def set_places_with_free_wifi
    @places_with_free_wifi = PartnersQuery.new(site: current_site).call(tag_slug: 'wifi')
  end
end
