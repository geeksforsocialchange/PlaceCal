# frozen_string_literal: true

# app/controllers/sites_controller.rb
class SitesController < ApplicationController
  before_action :set_primary_neighbourhood, only: [:site]
  before_action :set_site, only: [:index]
  before_action :set_places_to_get_online, only: [:index]

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

  def set_places_to_get_online
    @places_to_get_online = Partner
      .of_tag(Tag.find_by(slug: 'internet'))
      .for_site(current_site)
      .sort_by(&:name.downcase)
  end
end
