# frozen_string_literal: true

# app/controllers/sites_controller.rb
class SitesController < ApplicationController
  before_action :set_home_neighbourhood, only: [:site]
  before_action :set_site, only: [:index]

  def index
    render template: 'sites/default.html.erb'
  end

  def robots
    robots = File.read(Rails.root.join("config/robots/robots.#{Rails.env}.txt"))
    render plain: robots
  end
end
