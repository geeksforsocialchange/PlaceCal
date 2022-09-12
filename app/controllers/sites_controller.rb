# frozen_string_literal: true

# app/controllers/sites_controller.rb
class SitesController < ApplicationController
  before_action :set_primary_neighbourhood, only: [:site]
  before_action :set_site, only: [:index]
  before_action :set_places_to_get_computer_access, only: [:index]
  before_action :set_places_with_free_wifi, only: [:index]

  def index
    if current_site.slug == 'mossley'
      render template: "sites/#{current_site.slug}.html.erb"
    else
      render template: 'sites/default'
    end
  end

  def robots
    robots = File.read(Rails.root.join("config/robots/robots.#{Rails.env}.txt"))
    render plain: robots
  end

  private

  def set_places_to_get_computer_access
    tag = Tag.find_by(slug: 'computers')

    @places_to_get_computer_access = Partner.for_site_with_tag(current_site, tag)
  end

  def set_places_with_free_wifi
    tag = Tag.find_by(slug: 'wifi')

    @places_with_free_wifi = Partner.for_site_with_tag(current_site, tag)
  end
end
