class PagesController < ApplicationController
  def home
  end

  def site
    @site = Site.where(slug: request.subdomain).first
  end
end
