# frozen_string_literal: true

# TODO(#3163): Move to app/directory/controllers/partnerships_controller.rb
class PartnershipsController < ApplicationController
  before_action :set_site

  def index
    @partnerships = Site.where(is_published: true)
                        .where.not(slug: 'default-site')
                        .order(partners_count: :desc)
    @total_partners = Partner.visible.count

    render Views::Directory::PartnershipsIndex.new(partnerships: @partnerships, site: @site, query: params[:q], total_partners: @total_partners)
  end

  def show
    @partnership = Site.includes(:site_admin, :primary_neighbourhood).friendly.find(params[:id])
    @partners = PartnersQuery.new(site: @partnership).call
    @upcoming_events = EventsQuery.new(site: @partnership).call(period: 'upcoming')

    render Views::Directory::PartnershipShow.new(
      partnership: @partnership,
      partners: @partners,
      upcoming_events: @upcoming_events,
      site: @site
    )
  end
end
