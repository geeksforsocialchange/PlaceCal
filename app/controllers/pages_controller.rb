# frozen_string_literal: true

class PagesController < ApplicationController
  before_action :set_primary_neighbourhood, only: [:site]
  before_action :set_site

  def home
    @neighbourhoods = Site.published.select do |site|
      site.tags.none? { |tag| tag.type == 'Partnership' }
    end
    render Views::Pages::Home.new(neighbourhoods: @neighbourhoods)
  end

  def find_placecal
    @neighbourhoods = Site.published.select do |site|
      site.tags.none? { |tag| tag.type == 'Partnership' }
    end
    @partnerships = Site.published.select do |site|
      site.tags.any? { |tag| tag.type == 'Partnership' }
    end
    render Views::Pages::FindPlacecal.new(neighbourhoods: @neighbourhoods, partnerships: @partnerships)
  end

  def terms_of_use
    render Views::Pages::TermsOfUse.new
  end

  def privacy
    render Views::Pages::Privacy.new
  end

  def our_story
    render Views::Pages::OurStory.new
  end

  def community_groups
    render Views::Pages::CommunityGroups.new
  end

  def vcses
    render Views::Pages::Vcses.new
  end

  def housing_providers
    render Views::Pages::HousingProviders.new
  end

  def metropolitan_areas
    render Views::Pages::MetropolitanAreas.new
  end

  def social_prescribers
    render Views::Pages::SocialPrescribers.new
  end

  def culture_tourism
    render Views::Pages::CultureTourism.new
  end

  def robots
    if current_site
      render plain: current_site.robots
    else
      # Admin subdomain or no site found - disallow all indexing
      render plain: "User-agent: *\nDisallow: /"
    end
  end
end
