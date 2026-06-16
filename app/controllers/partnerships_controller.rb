# frozen_string_literal: true

# TODO(#3163): Move to app/directory/controllers/partnerships_controller.rb
class PartnershipsController < ApplicationController
  before_action :set_site

  def index
    render Views::Directory::Partnerships::Index.new(
      partnerships: PartnershipsQuery.new.call(query: params[:q]),
      site: @site,
      query: params[:q],
      partnership_count: Site.published.count,
      total_partners: Partner.visible.count
    )
  end

  def show
    @partnership = Site.includes(:site_admin, :primary_neighbourhood).friendly.find(params[:id])
    @partners = PartnersQuery.new(site: @partnership).call
    @upcoming_events = EventsQuery.new(site: @partnership).call(period: 'future')

    flat_partners = Array(@partners.respond_to?(:each_pair) ? @partners.values.flatten : @partners)
    @event_count = EventsQuery.new(site: @partnership).scope
                              .where(dtstart: Time.zone.today..30.days.from_now)
                              .count

    render Views::Directory::Partnerships::Show.new(
      partnership: @partnership,
      partners: @partners,
      upcoming_events: @upcoming_events,
      partner_event_counts: EventsQuery.upcoming_counts_by_partner(flat_partners.map(&:id)),
      partner_locations: partner_map_locations(flat_partners),
      event_count: @event_count,
      site: @site
    )
  end

  private

  # Map markers for the partnership's partners that have geocoded addresses.
  def partner_map_locations(partners)
    partners.filter_map do |partner|
      next unless partner.address&.latitude

      { lat: partner.address.latitude, lon: partner.address.longitude, name: partner.name, url: partner_path(partner) }
    end
  end
end
