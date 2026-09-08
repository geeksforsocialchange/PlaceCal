# frozen_string_literal: true

class PartnersController < ApplicationController
  include MapMarkers
  include OffsiteRedirect
  include Pagy::Offset::Method

  before_action :set_partner, only: %i[show embed]
  before_action :set_day, only: %i[show embed]
  before_action :set_primary_neighbourhood, only: [:index]
  before_action :set_site
  before_action :set_title, only: %i[index show]

  PAGINATION_THRESHOLD = 30
  # Default/step size for the days-based "Show N more days" paging on the
  # events browser, and the upper bound a visitor can page their way out to.
  DAYS_DEFAULT = 4
  DAYS_MAX = 52

  # GET /partners
  # GET /partners.json
  def index
    if directory_request?
      render_directory_index
    else
      render_local_index
    end
  end

  # GET /partners/1
  # GET /partners/1.json
  def show
    return redirect_to root_path if @partner.hidden

    redirect_offsite_to_permalink(PartnersQuery.new(site: current_site), @partner)
    return if performed?

    @days = clamp_days(params[:days])
    assign_events_for_show

    # Map
    @map = get_map_markers([@partner])

    @containing_sites = Site.sites_that_contain_partner(@partner) if directory_request?

    respond_to do |format|
      format.html do
        view_class = directory_request? ? Views::Directory::Partners::Show : Views::Partners::Show
        render view_class.new(
          partner: @partner, site: @site, current_day: @current_day,
          map: @map, events: @events,
          period: @period, date_period: @date_period, sort: @sort,
          repeating: @repeating, no_event_message: @no_event_message,
          paginator: @paginator, show_monthly: @show_monthly || false,
          containing_sites: @containing_sites,
          days: @days, more_days: @more_days || 0,
          events_total_count: @events_total_count, events_total_days: @events_total_days
        )
      end
      format.ics do
        track_ical_download
        cal = create_calendar(Event.by_organiser_or_place(@partner).ical_feed, "#{@partner} - Powered by PlaceCal")
        cal.publish
        render plain: cal.to_ical
      end
      format.csv do
        track_csv_download
        events = Event.by_organiser_or_place(@partner).upcoming.sort_by_time
        site_url = current_site&.url || 'https://placecal.org'
        send_data EventsCsv.new(events, site_url: site_url).call,
                  filename: "#{@partner.slug}-events.csv", type: :csv
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

  # Splits the partner show page's three event-listing branches out of #show
  # to keep that action's complexity in check: no events, a handful of events
  # (flat, day-windowed), or many events (paginated, day-windowed by default
  # or the older Timeline/EventFilter paginator for an explicit period).
  def assign_events_for_show
    upcoming_count = Event.by_organiser_or_place(@partner).upcoming.count
    if upcoming_count.zero?
      @events = []
      @no_event_message = no_upcoming_events_reason(@partner)
    elsif upcoming_count < PAGINATION_THRESHOLD
      assign_flat_events
    else
      assign_paginated_events
    end
  end

  # If only a few events, show them all with no pagination. The local-site
  # view windows this by day (new events browser); the directory view keeps
  # its own client-revealed overflow list, so it gets the whole future set.
  def assign_flat_events
    @repeating = params[:repeating] || 'on'
    @paginator = false
    query = EventsQuery.new(site: nil, day: @current_day)
    if directory_request?
      @events = query.call(period: 'future', organiser_or_place: @partner, repeating: @repeating, sort: 'time')
    else
      assign_days_windowed_events(sort: 'time', query: query)
    end
  end

  # If a lot, paginate - default to "upcoming". On the local-site view this
  # shows the first few days of events, windowed the same way as the flat
  # branch above; an explicit day/week/month period keeps the older
  # Timeline/EventFilter paginator instead (see
  # Views::Partners::Show#render_events_paginator). The directory view isn't
  # day-windowed - it keeps its original "next 10, reveal more" behaviour.
  def assign_paginated_events
    weekly_count = Event.by_organiser(@partner).find_next_7_days(@current_day).count
    @date_period = weekly_count >= EventsQuery::WEEKLY_DENSITY_THRESHOLD ? 'week' : 'month'
    @period = params[:period] || 'upcoming'
    @sort = params[:sort] || 'time'
    @repeating = params[:repeating] || 'on'
    @paginator = true

    query = EventsQuery.new(site: nil, day: @current_day)
    if !directory_request? && @period == 'upcoming'
      assign_days_windowed_events(sort: @sort, query: query)
    else
      @events = query.call(period: @period, organiser_or_place: @partner, repeating: @repeating, sort: @sort)
    end
    @show_monthly = query.show_monthly?
  end

  # Fetches the partner's whole upcoming set (after the repeating filter,
  # capped like any other "future" listing at EventsQuery::FUTURE_LIMIT) and
  # windows it down to the first `@days` distinct days. The un-windowed
  # totals are kept so the events browser header can report the full count
  # ("23 events across 20 days") independent of how many days are on screen.
  def assign_days_windowed_events(sort:, query: EventsQuery.new(site: nil, day: @current_day))
    full_events = query.call(period: 'future', organiser_or_place: @partner, repeating: @repeating, sort: sort)
    @events_total_count = full_events.values.sum(&:size)
    @events_total_days = full_events.size
    @events = full_events.first(@days).to_h
    @more_days = @events_total_days - @events.size
  end

  def clamp_days(raw_days)
    raw_days.presence&.to_i&.clamp(1, DAYS_MAX) || DAYS_DEFAULT
  end

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
    filters = {
      query: params[:q],
      tag_id: params[:category],
      partnership_id: params[:partnership],
      neighbourhood_id: params[:neighbourhood]
    }
    partners = query.call(**filters, sort: @sort)
    paginate_with_az_filter(partners)

    # Each facet's counts cross-filter on the OTHER active filters but not its
    # own, so the numbers narrow as you filter while you can still switch within
    # a facet (e.g. the category list reflects the chosen neighbourhood).
    category_scope = query.call(**filters.except(:tag_id))
    partnership_scope = query.call(**filters.except(:partnership_id))
    neighbourhood_scope = query.call(**filters.except(:neighbourhood_id))

    render Views::Directory::Partners::Index.new(
      partners: @partners, pagy: @pagy, site: @site, query: params[:q], sort: @sort,
      az_letters: @az_letters, selected_letter: @selected_letter,
      area_labels: PartnersQuery.area_labels(@partners),
      total_count: Partner.visible.count,
      partnership_count: Site.where(is_published: true).count,
      categories: query.categories_with_counts(scope: category_scope).map { |c| { id: c[:category].id, name: c[:category].name, count: c[:count] } },
      partnerships_list: query.partnerships_with_counts(scope: partnership_scope).map { |p| { id: p[:partnership].id, name: p[:partnership].name, count: p[:count] } },
      neighbourhoods_tree: query.neighbourhood_tree(scope: neighbourhood_scope, selected_id: params[:neighbourhood]),
      selected_category: params[:category],
      selected_partnership: params[:partnership],
      selected_neighbourhood: params[:neighbourhood]
    )
  end

  def paginate_with_az_filter(partners)
    if @sort == 'name'
      # reorder(nil) drops the name ORDER BY: with a DISTINCT relation (added by
      # the neighbourhood filter) Postgres rejects ordering by a column that's
      # not in the restricted DISTINCT select list. See issue #3226.
      @az_letters = partners.reorder(nil).pluck(Arel.sql('UPPER(LEFT(partners.name, 1))')).uniq.select { |l| l&.match?(/[A-Z]/) }.to_set
      @selected_letter = params[:letter]&.upcase if params[:letter].present? && params[:letter].match?(/\A[a-zA-Z]\z/)
      filtered = @selected_letter ? partners.where('partners.name LIKE ?', "#{@selected_letter}%") : partners
      @pagy, @partners = pagy(filtered, limit: 30)
    else
      @az_letters = Set.new
      @selected_letter = nil
      @pagy, @partners = pagy(partners, limit: 30)
    end
  end

  def render_local_index
    @selected_category = params[:category] if params[:category].present? && Integer(params[:category], exception: false)
    @selected_neighbourhood = params[:neighbourhood] if params[:neighbourhood].present? && Integer(params[:neighbourhood], exception: false)

    @region = current_region
    query = PartnersQuery.new(site: current_site)
    @partners = query.call(
      neighbourhood_id: @selected_neighbourhood,
      tag_id: @selected_category,
      partnership_id: @region&.id
    )

    @map = get_map_markers(@partners) if @partners.detect(&:address)

    render Views::Partners::Index.new(
      partners: @partners, site: @site,
      map: @map, selected_category: @selected_category,
      selected_neighbourhood: @selected_neighbourhood,
      region_tags: region_tags, selected_region: @region,
      query: query
    )
  end
end
