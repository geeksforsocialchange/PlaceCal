# frozen_string_literal: true

class PagesController < ApplicationController
  before_action :set_primary_neighbourhood, only: [:site]
  before_action :set_site

  def home
    @neighbourhoods = Site.published.select do |site|
      site.tags.none? { |tag| tag.type == 'Partnership' }
    end
  end

  def find_placecal
    @neighbourhoods = Site.published.select do |site|
      site.tags.none? { |tag| tag.type == 'Partnership' }
    end
    @partnerships = Site.published.select do |site|
      site.tags.any? { |tag| tag.type == 'Partnership' }
    end
  end

  def terms_of_use; end

  def robots
    render plain: current_site.robots
  end
end
