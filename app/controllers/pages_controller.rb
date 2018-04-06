class PagesController < ApplicationController
  def home
  end

  def robots
    robots = File.read(Rails.root.join("config/robots/robots.#{Rails.env}.txt"))
    render plain: robots
  end
end
