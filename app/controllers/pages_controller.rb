# frozen_string_literal: true

class PagesController < ApplicationController
  before_action :set_primary_neighbourhood, only: [:site]
  before_action :set_site

  def home; end

  def find_placecal
    @grouped_sites = Site.where(is_published: true)
                         .joins(:primary_neighbourhood)
                         .merge(Neighbourhood.order(district: :asc))
                         .group_by{ |s| s.primary_neighbourhood.district }


  end

  def robots
    robots = File.read(Rails.root.join("config/robots/robots.#{Rails.env}.txt"))
    render plain: robots
  end
end
