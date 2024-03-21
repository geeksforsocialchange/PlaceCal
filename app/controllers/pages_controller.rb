# frozen_string_literal: true

class PagesController < ApplicationController
  before_action :set_primary_neighbourhood, only: [:site]
  before_action :set_site

  def home
    @neighbourhoods = Site.published.select do |site|
      site.partnership.none? { |tag| tag.type == 'Partnership' }
    end
  end

  def find_placecal
    @neighbourhoods = Site.published.select do |site|
      site.partnership.none? { |tag| tag.type == 'Partnership' }
    end
    @partnerships = Site.published.select do |site|
      site.partnership.any? { |tag| tag.type == 'Partnership' }
    end
  end

  def robots
    robots = File.read(Rails.root.join("config/robots/robots.#{Rails.env}.txt"))
    render plain: robots
  end
end
