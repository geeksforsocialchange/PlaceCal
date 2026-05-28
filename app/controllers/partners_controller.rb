# frozen_string_literal: true

class PartnersController < ApplicationController
  include MapMarkers
  include Pagy::Offset::Method

  before_action :set_partner, only: %i[show embed]
  before_action :set_day, only: %i[show embed]
  before_action :set_primary_neighbourhood, only: [:index]
  before_action :set_site
  before_action :set_title, only: %i[index show]

  PAGINATION_THRESHOLD = 30

  # GET /partners
  # GET /partners.json
  def index
    if default_site?
      render_directory_index
    else
      render_local_index
    end
  end

  # GET /partners/1
  # GET /partners/1.json
  def show
    redirect_to root_path if @partner.hidden

    upcoming_count = Event.by_organiser_or_place(@partner).upcoming.count
    if upcoming_count.zero?
      # If no events, show an appropriate message why
      @events = []
      @no_event_message = no_upcoming_events_reason(@partner)
    elsif upcoming_count < PAGINATION_THRESHOLD
      # If only a few, show them all with no pagination
      query = EventsQuery.new(site: nil, day: @current_day)
      @events = query.call(period: 'future', organiser_or_place: @partner, sort: 'time')
      @paginator = false
    else
      # If a lot, paginate - default to "upcoming" which shows next N events
      partner_events = Event.by_organiser(@partner)
      weekly_count = partner_events.find_next_7_days(@current_day).count
      @date_period = weekly_count >= EventsQuery::WEEKLY_DENSITY_THRESHOLD ? 'week' : 'month'
      @period = params[:period] || 'upcoming'
      @sort = params[:sort] || 'time'
      @repeating = params[:repeating] || 'on'
      query = EventsQuery.new(site: nil, day: @current_day)
      @events = query.call(
        period: @period,
        organiser_or_place: @partner,
        repeating: @repeating,
        sort: @sort
      )
      @show_monthly = query.show_monthly?
      @paginator = true
    end

    # Map
    @map = get_map_markers([@partner])

    @containing_sites = Site.sites_that_contain_partner(@partner) if default_site?

    respond_to do |format|
      format.html do
        view_class = default_site? ? Views::Directory::PartnerShow : Views::Partners::Show
        render view_class.new(
          partner: @partner, site: @site, current_day: @current_day,
          map: @map, events: @events,
          period: @period, date_period: @date_period, sort: @sort,
          repeating: @repeating, no_event_message: @no_event_message,
          paginator: @paginator, show_monthly: @show_monthly || false,
          containing_sites: @containing_sites
        )
      end
      format.ics do
        track_ical_download
        cal = create_calendar(Event.by_organiser_or_place(@partner).ical_feed, "#{@partner} - Powered by PlaceCal")
        cal.publish
        render plain: cal.to_ical
      end
    end
  end

  def embed
    period = params[:period] || 'week'
    limit = params[:limit]&.to_i || 10
    query = EventsQuery.new(site: nil, day: @current_day)
    @events = query.call(period: period, place: @partner, sort: 'time', limit: limit)
    response.headers.except! 'X-Frame-Options'
    render layout: false
  end

  private

  def no_upcoming_events_reason(partner)
    if partner.calendars.none?
      'This partner does not list events on PlaceCal.'
    else
      'This partner has no upcoming events.'
    end
  end

  def set_title
    @title =
      if current_site&.primary_neighbourhood
        "Partners #{current_site.join_word} #{current_site.primary_neighbourhood.name}"
      else
        'All Partners'
      end
  end

  def render_directory_index
    @sort = params[:sort] || 'recent'
    query = PartnersQuery.new(site: current_site)
    partners = query.call(
      query: params[:q],
      tag_id: params[:category],
      partnership_id: params[:partnership],
      neighbourhood_id: params[:neighbourhood],
      sort: @sort
    )
    paginate_with_az_filter(partners)

    render Views::Directory::PartnersIndex.new(
      partners: @partners, pagy: @pagy, site: @site, query: params[:q], sort: @sort,
      az_letters: @az_letters, selected_letter: @selected_letter,
      total_count: Partner.visible.count,
      partnership_count: Site.where(is_published: true).where.not(slug: 'default-site').count,
      categories: query.categories_with_counts.map { |c| { id: c[:category].id, name: c[:category].name, count: c[:count] } },
      partnerships_list: query.partnerships_with_counts.map { |p| { id: p[:partnership].id, name: p[:partnership].name, count: p[:count] } },
      neighbourhoods: group_neighbourhoods_by_district(query.neighbourhoods_with_counts),
      selected_category: params[:category],
      selected_partnership: params[:partnership],
      selected_neighbourhood: params[:neighbourhood]
    )
  end

  def paginate_with_az_filter(partners)
    if @sort == 'name'
      @az_letters = partners.pluck(Arel.sql('UPPER(LEFT(partners.name, 1))')).uniq.select { |l| l&.match?(/[A-Z]/) }.to_set
      @selected_letter = params[:letter]&.upcase if params[:letter].present? && params[:letter].match?(/\A[a-zA-Z]\z/)
      filtered = @selected_letter ? partners.where('partners.name LIKE ?', "#{@selected_letter}%") : partners
      @pagy, @partners = pagy(filtered, limit: 30)
    else
      @az_letters = Set.new
      @selected_letter = nil
      @pagy, @partners = pagy(partners, limit: 30)
    end
  end

  def group_neighbourhoods_by_district(neighbourhoods_with_counts)
    grouped = neighbourhoods_with_counts
              .group_by { |n| n[:neighbourhood].district&.shortname || n[:neighbourhood].shortname }
              .map do |district_name, items|
                {
                  group: district_name,
                  items: items.map { |n| { id: n[:neighbourhood].id, name: n[:neighbourhood].shortname, count: n[:count] } }
                }
              end
    grouped.sort_by { |g| g[:group] }
  end

  def render_local_index
    @selected_category = params[:category] if params[:category].present? && Integer(params[:category], exception: false)
    @selected_neighbourhood = params[:neighbourhood] if params[:neighbourhood].present? && Integer(params[:neighbourhood], exception: false)

    query = PartnersQuery.new(site: current_site)
    @partners = query.call(
      neighbourhood_id: @selected_neighbourhood,
      tag_id: @selected_category
    )

    @map = get_map_markers(@partners) if @partners.detect(&:address)

    render Views::Partners::Index.new(
      partners: @partners, site: @site,
      map: @map, selected_category: @selected_category,
      selected_neighbourhood: @selected_neighbourhood
    )
  end
end
