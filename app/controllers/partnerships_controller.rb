# frozen_string_literal: true

# TODO(#3163): Move to app/directory/controllers/partnerships_controller.rb
class PartnershipsController < ApplicationController
  before_action :set_site

  def index
    @partnerships = Site.where(is_published: true)
                        .order(partners_count: :desc)
    @total_partners = Partner.visible.count

    render Views::Directory::Partnerships::Index.new(partnerships: @partnerships, site: @site, query: params[:q], total_partners: @total_partners)
  end

  def show
    @partnership = Site.includes(:site_admin, :primary_neighbourhood).friendly.find(params[:id])
    @partners = PartnersQuery.new(site: @partnership).call
    @upcoming_events = EventsQuery.new(site: @partnership).call(period: 'future')

    partner_ids = Array(@partners.respond_to?(:each_pair) ? @partners.values.flatten : @partners).map(&:id)
    @partner_event_counts = Event.future(Time.current)
                                 .where(place_id: partner_ids)
                                 .or(Event.future(Time.current).where(organiser_id: partner_ids))
                                 .group(:place_id)
                                 .count

    @event_count = EventsQuery.new(site: @partnership).scope
                              .where(dtstart: Time.zone.today..30.days.from_now)
                              .count

    render Views::Directory::Partnerships::Show.new(
      partnership: @partnership,
      partners: @partners,
      upcoming_events: @upcoming_events,
      partner_event_counts: @partner_event_counts,
      event_count: @event_count,
      site: @site
    )
  end
end
