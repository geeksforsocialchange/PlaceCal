# frozen_string_literal: true

class PagesController < ApplicationController
  before_action :set_home_neighbourhood, only: [:site]
  before_action :set_site

  def home; end

  def robots
    robots = File.read(Rails.root.join("config/robots/robots.#{Rails.env}.txt"))
    render plain: robots
  end
end
