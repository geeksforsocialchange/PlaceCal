class PagesController < ApplicationController
  def home
  end

  def turf
    @turf = Turf.where(slug: request.subdomain).first
  end
end
