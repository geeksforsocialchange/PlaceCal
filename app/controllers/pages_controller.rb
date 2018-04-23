class PagesController < ApplicationController
  before_action :get_home_turf, only: [:site]

  def home
  end

  def site
  end
end
