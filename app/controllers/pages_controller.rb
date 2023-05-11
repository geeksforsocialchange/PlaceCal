# frozen_string_literal: true

class PagesController < ApplicationController
  before_action :set_primary_neighbourhood, only: [:site]
  before_action :set_site

  def home
    @sites = Site.where(id: [9, 14, 19, 21]).reverse
  end

  def find_placecal
    @sites = Site.where(id: [9, 14, 19, 21]).reverse
  end

  def robots
    robots = File.read(Rails.root.join("config/robots/robots.#{Rails.env}.txt"))
    render plain: robots
  end
end
