class PagesController < ApplicationController
  before_action :get_home_turf, only: [:site]

  def home
  end

  def robots
    robots = File.read(Rails.root.join("config/robots/robots.#{Rails.env}.txt"))
    render plain: robots
  end
end
